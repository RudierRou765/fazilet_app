#!/usr/bin/env node
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StandardMcpServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolResult,
  TextContent,
  ImageContent,
  EmbeddedResource,
} from '@modelcontextprotocol/sdk/types.js';
import { z } from 'zod';
import * as path from 'path';
import * as fs from 'fs/promises';
import * as fsSync from 'fs';
import Database from 'better-sqlite3';
import * as archiver from 'archiver';
import * as os from 'os';
import { v4 as uuidv4 } from 'uuid';

// ====================
// Types & Interfaces
// ====================

interface DistrictRecord {
  DistrictID: number;
  Name: string;
  CityID: number;
  CountryID: number;
  Latitude: number;
  Longitude: number;
  TimeZone: string;
  FajrOffset: number;
  DhuhrOffset: number;
  AsrOffset: number;
  MaghribOffset: number;
  IshaOffset: number;
}

interface BookMetadata {
  BookID: number;
  Title: string;
  Language: string;
  Version: string;
  TotalFragments: number;
}

interface SearchResult {
  type: 'book' | 'district' | 'log';
  id: string;
  title: string;
  snippet: string;
  relevance: number;
}

// ====================
// Server Initialization
// ====================

const server = new McpServer({
  name: 'fazilet-mcp-server',
  version: '1.0.0',
  description:
    'Fazilet MCP Server — Asset management, coordinate DB engine, and enterprise search for Fazilet ecosystem (Node.js/TypeScript)',
});

// ====================
// Paths & Configuration
// ====================

const DATA_DIR = path.join(os.homedir(), '.fazilet-mcp', 'data');
const BOOKS_DIR = path.join(DATA_DIR, 'books');
const DISTRICTS_DB_PATH = path.join(DATA_DIR, 'districts.sqlite');
const LOGS_DIR = path.join(DATA_DIR, 'logs');
const METADATA_DIR = path.join(DATA_DIR, 'metadata');

// Ensure directories exist
async function ensureDirectories(): Promise<void> {
  const dirs = [DATA_DIR, BOOKS_DIR, LOGS_DIR, METADATA_DIR];
  for (const dir of dirs) {
    await fs.mkdir(dir, { recursive: true });
  }
}

// ====================
// Database Helpers
// ====================

function getDistrictsDb(): Database.Database {
  const db = new Database(DISTRICTS_DB_PATH);
  db.pragma('journal_mode = WAL');
  return db;
}

function getBookDb(bookFilename: string): Database.Database {
  const bookPath = path.join(BOOKS_DIR, bookFilename);
  if (!fsSync.existsSync(bookPath)) {
    throw new Error(`Book database not found: ${bookFilename}`);
  }
  const db = new Database(bookPath);
  return db;
}

// ====================
// Tool 1: Asset Manager — Upload Book Fragment
// ====================

server.tool(
  'upload_book_fragment',
  'Upload a fragmented book SQLite file from the React CMS. Accepts a base64-encoded file buffer and metadata. Returns the saved filename.',
  {
    fileBuffer: z
      .string()
      .describe('Base64-encoded SQLite file buffer for the book fragment'),
    language: z
      .string()
      .min(2)
      .max(5)
      .describe('Language code (e.g., "tr", "en")'),
    bookId: z
      .number()
      .int()
      .positive()
      .describe('Unique book identifier'),
    fragmentIndex: z
      .number()
      .int()
      .min(0)
      .describe('Fragment index (0-based order for stitching)'),
    title: z.string().min(1).describe('Book title'),
    checksum: z
      .string()
      .optional()
      .describe('Optional MD5/SHA checksum for validation'),
  },
  async (args): Promise<CallToolResult> => {
    try {
      const { fileBuffer, language, bookId, fragmentIndex, title, checksum } = args;

      // Validate base64
      let buffer: Buffer;
      try {
        buffer = Buffer.from(fileBuffer, 'base64');
      } catch (e) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: Invalid base64 file buffer — ${e instanceof Error ? e.message : 'unknown error'}`,
            } as TextContent,
          ],
          isError: true,
        };
      }

      // Validate file signature (SQLite magic bytes: "SQLite format 3\000")
      if (buffer.length < 16 || !buffer.slice(0, 15).equals(Buffer.from('SQLite format 3\000'))) {
        return {
          content: [
            {
              type: 'text',
              text: 'Error: Uploaded file is not a valid SQLite database (missing SQLite format 3 header)',
            } as TextContent,
          ],
          isError: true,
        };
      }

      // Save fragment
      const langDir = path.join(BOOKS_DIR, language);
      await fs.mkdir(langDir, { recursive: true });

      const filename = `${bookId}_fragment_${fragmentIndex}.sqlite`;
      const filePath = path.join(langDir, filename);
      await fs.writeFile(filePath, buffer);

      // Update fragment registry in metadata
      const registryPath = path.join(METADATA_DIR, `${bookId}_registry.json`);
      let registry: any = { fragments: [], title, language, bookId };
      if (fsSync.existsSync(registryPath)) {
        registry = JSON.parse(await fs.readFile(registryPath, 'utf-8'));
      }
      registry.fragments.push({
        index: fragmentIndex,
        filename,
        path: filePath,
        uploadedAt: new Date().toISOString(),
        checksum: checksum ?? 'unknown',
      });
      await fs.writeFile(registryPath, JSON.stringify(registry, null, 2));

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(
              {
                success: true,
                filename,
                path: filePath,
                fragmentIndex,
                message: `Fragment ${fragmentIndex} uploaded successfully for book ${bookId}`,
              },
              null,
              2
            ),
          } as TextContent,
        ],
      };
    } catch (e) {
      return {
        content: [
          {
            type: 'text',
            text: `Error uploading book fragment: ${e instanceof Error ? e.message : 'unknown error'}`,
          } as TextContent,
        ],
        isError: true,
      };
    }
  },
  {
    readOnlyHint: false,
    destructiveHint: false,
    idempotentHint: false,
    openWorldHint: true,
  }
);

// ====================
// Tool 2: Compile Book
// ====================

server.tool(
  'compile_book',
  'Compile uploaded fragmented SQLite files into a single, compressed .sqlite file for Flutter app. Generates metadata.json with version and checksum.',
  {
    bookId: z
      .number()
      .int()
      .positive()
      .describe('Book ID to compile'),
    outputFilename: z
      .string()
      .min(1)
      .describe('Output filename (e.g., "ilmihal_tr.sqlite")'),
    version: z
      .string()
      .optional()
      .describe('Version string (default: ISO timestamp)'),
  },
  async (args): Promise<CallToolResult> => {
    try {
      const { bookId, outputFilename, version } = args;

      // Load registry
      const registryPath = path.join(METADATA_DIR, `${bookId}_registry.json`);
      if (!fsSync.existsSync(registryPath)) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: No fragments found for book ID ${bookId}. Upload fragments first.`,
            } as TextContent,
          ],
          isError: true,
        };
      }

      const registry = JSON.parse(await fs.readFile(registryPath, 'utf-8'));
      const fragments = registry.fragments.sort(
        (a: any, b: any) => a.index - b.index
      );

      if (fragments.length === 0) {
        return {
          content: [
            {
              type: 'text',
              text: `Error: No fragments registered for book ID ${bookId}`,
            } as TextContent,
          ],
          isError: true,
        };
      }

      // Create compiled database
      const outputPath = path.join(BOOKS_DIR, outputFilename);
      const db = new Database(outputPath);
      db.pragma('journal_mode = WAL');

      try {
        // Create book_meta table
        db.exec(`
          CREATE TABLE IF NOT EXISTS book_meta (
            BookID INTEGER PRIMARY KEY,
            Title TEXT NOT NULL,
            Language TEXT NOT NULL,
            Version TEXT NOT NULL,
            TotalFragments INTEGER NOT NULL
          )
        `);

        // Create book_content table
        db.exec(`
          CREATE TABLE IF NOT EXISTS book_content (
            FragmentID INTEGER NOT NULL,
            ChapterID INTEGER NOT NULL,
            SectionID INTEGER,
            Content TEXT NOT NULL,
            OrderIndex INTEGER NOT NULL,
            PRIMARY KEY(FragmentID, ChapterID)
          )
        `);

        // Copy data from each fragment
        let orderIndex = 0;
        const insertStmt = db.prepare(`
          INSERT INTO book_content (FragmentID, ChapterID, SectionID, Content, OrderIndex)
          VALUES (?, ?, ?, ?, ?)
        `);

        for (const frag of fragments) {
          const fragDb = new Database(frag.path);
          try {
            const rows = fragDb.prepare('SELECT * FROM book_content').all() as any[];
            for (const row of rows) {
              insertStmt.run(
                row.FragmentID,
                row.ChapterID,
                row.SectionID ?? null,
                row.Content,
                orderIndex++
              );
            }
          } finally {
            fragDb.close();
          }
        }

        // Insert metadata
        const bookVersion = version ?? new Date().toISOString();
        db.prepare(
          `INSERT OR REPLACE INTO book_meta (BookID, Title, Language, Version, TotalFragments)
           VALUES (?, ?, ?, ?, ?)`
        ).run(bookId, registry.title, registry.language, bookVersion, fragments.length);

        // Create FTS5 virtual table
        try {
          db.exec(`
            CREATE VIRTUAL TABLE IF NOT EXISTS book_search
            USING fts5(Content, content=book_content, content_rowid=rowid)
          `);
          db.exec(`
            INSERT INTO book_search(rowid, Content)
            SELECT rowid, Content FROM book_content
          `);
        } catch (ftsError) {
          // FTS5 might not be available, that's okay
        }

        db.pragma('optimize');
      } finally {
        db.close();
      }

      // Generate metadata.json
      const stats = await fs.stat(outputPath);
      const checksum = await generateChecksum(outputPath);
      const metadata = {
        bookId,
        title: registry.title,
        language: registry.language,
        version: version ?? new Date().toISOString(),
        compiledAt: new Date().toISOString(),
        filename: outputFilename,
        sizeBytes: stats.size,
        checksum,
        fragmentCount: fragments.length,
        downloadUrl: `/api/v1/assets/books/${outputFilename}`,
      };

      const metadataPath = path.join(BOOKS_DIR, `${outputFilename}.metadata.json`);
      await fs.writeFile(metadataPath, JSON.stringify(metadata, null, 2));

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(
              {
                success: true,
                outputPath,
                metadataPath,
                metadata,
                message: `Book ${bookId} compiled successfully with ${fragments.length} fragments`,
              },
              null,
              2
            ),
          } as TextContent,
        ],
      };
    } catch (e) {
      return {
        content: [
          {
            type: 'text',
            text: `Error compiling book: ${e instanceof Error ? e.message : 'unknown error'}`,
          } as TextContent,
        ],
        isError: true,
      };
    }
  },
  {
    readOnlyHint: false,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: false,
  }
);

// ====================
// Tool 3: List Books
// ====================

server.tool(
  'list_books',
  'List all compiled books with their metadata.',
  {
    language: z
      .string()
      .optional()
      .describe('Filter by language code (e.g., "tr", "en")'),
  },
  async (args): Promise<CallToolResult> => {
    try {
      const { language } = args;
      const files = await fs.readdir(BOOKS_DIR);

      const books: any[] = [];
      for (const file of files) {
        if (!file.endsWith('.sqlite')) continue;
        const metadataPath = path.join(BOOKS_DIR, `${file}.metadata.json`);
        if (fsSync.existsSync(metadataPath)) {
          const metadata = JSON.parse(await fs.readFile(metadataPath, 'utf-8'));
          if (language && metadata.language !== language) continue;
          books.push(metadata);
        }
      }

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({ success: true, count: books.length, books }, null, 2),
          } as TextContent,
        ],
      };
    } catch (e) {
      return {
        content: [
          {
            type: 'text',
            text: `Error listing books: ${e instanceof Error ? e.message : 'unknown error'}`,
          } as TextContent,
        ],
        isError: true,
      };
    }
  },
  {
    readOnlyHint: true,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: false,
  }
);

// ====================
// Tool 4: Get District
// ====================

server.tool(
  'get_district',
  'Get a single district by ID from the districts database.',
  {
    districtId: z
      .number()
      .int()
      .positive()
      .describe('District ID to retrieve'),
  },
  async (args): Promise<CallToolResult> => {
    try {
      const { districtId } = args;
      const db = getDistrictsDb();
      try {
        const row = db.prepare('SELECT * FROM districts WHERE DistrictID = ?').get(districtId) as
          | DistrictRecord
          | undefined;
        if (!row) {
          return {
            content: [
              {
                type: 'text',
                text: `Error: District with ID ${districtId} not found`,
              } as TextContent,
            ],
            isError: true,
          };
        }
        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify({ success: true, district: row }, null, 2),
            } as TextContent,
          ],
        };
      } finally {
        db.close();
      }
    } catch (e) {
      return {
        content: [
          {
            type: 'text',
            text: `Error getting district: ${e instanceof Error ? e.message : 'unknown error'}`,
          } as TextContent,
        ],
        isError: true,
      };
    }
  },
  {
    readOnlyHint: true,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: false,
  }
);

// ====================
// Tool 5: List Districts
// ====================

server.tool(
  'list_districts',
  'List districts with optional filtering and pagination. Supports search by name and filtering by city/country.',
  {
    query: z
      .string()
      .optional()
      .describe('Search query for district name (partial match)'),
    cityId: z
      .number()
      .int()
      .optional()
      .describe('Filter by City ID'),
    countryId: z
      .number()
      .int()
      .optional()
      .describe('Filter by Country ID'),
    limit: z
      .number()
      .int()
      .min(1)
      .max(1000)
      .default(50)
      .describe('Max results (default: 50)'),
    offset: z
      .number()
      .int()
      .min(0)
      .default(0)
      .describe('Pagination offset (default: 0)'),
  },
  async (args): Promise<CallToolResult> => {
    try {
      const { query, cityId, countryId, limit, offset } = args;
      const db = getDistrictsDb();
      try {
        let sql = 'SELECT * FROM districts WHERE 1=1';
        const params: any[] = [];

        if (query) {
          sql += ' AND Name LIKE ?';
          params.push(`%${query}%`);
        }
        if (cityId !== undefined) {
          sql += ' AND CityID = ?';
          params.push(cityId);
        }
        if (countryId !== undefined) {
          sql += ' AND CountryID = ?';
          params.push(countryId);
        }

        sql += ' ORDER BY CountryID, CityID, Name ASC';
        sql += ' LIMIT ? OFFSET ?';
        params.push(limit, offset);

        const rows = db.prepare(sql).all(...params) as DistrictRecord[];
        const totalCount = db
          .prepare('SELECT COUNT(*) as count FROM districts')
          .get() as { count: number };

        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(
                {
                  success: true,
                  count: rows.length,
                  totalCount: totalCount.count,
                  offset,
                  limit,
                  districts: rows,
                },
                null,
                2
              ),
            } as TextContent,
          ],
        };
      } finally {
        db.close();
      }
    } catch (e) {
      return {
        content: [
          {
            type: 'text',
            text: `Error listing districts: ${e instanceof Error ? e.message : 'unknown error'}`,
          } as TextContent,
        ],
        isError: true,
      };
    }
  },
  {
    readOnlyHint: true,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: false,
  }
);

// ====================
// Tool 6: Update District Offsets
// ====================

server.tool(
  'update_district_offsets',
  'Update per-prayer Fazilet methodology offsets for a specific district. All offsets are in seconds.',
  {
    districtId: z
      .number()
      .int()
      .positive()
      .describe('District ID to update'),
    fajrOffset: z
      .number()
      .int()
      .describe('Fajr prayer offset in seconds'),
    dhuhrOffset: z
      .number()
      .int()
      .describe('Dhuhr prayer offset in seconds'),
    asrOffset: z
      .number()
      .int()
      .describe('Asr prayer offset in seconds'),
    maghribOffset: z
      .number()
      .int()
      .describe('Maghrib prayer offset in seconds'),
    ishaOffset: z
      .number()
      .int()
      .describe('Isha prayer offset in seconds'),
  },
  async (args): Promise<CallToolResult> => {
    try {
      const { districtId, fajrOffset, dhuhrOffset, asrOffset, maghribOffset, ishaOffset } = args;
      const db = getDistrictsDb();
      try {
        // Check if district exists
        const existing = db
          .prepare('SELECT DistrictID FROM districts WHERE DistrictID = ?')
          .get(districtId);
        if (!existing) {
          return {
            content: [
              {
                type: 'text',
                text: `Error: District with ID ${districtId} not found`,
              } as TextContent,
            ],
            isError: true,
          };
        }

        // Build dynamic update query
        const updates: string[] = [];
        const params: any[] = [];
        if (fajrOffset !== undefined) {
          updates.push('FajrOffset = ?');
          params.push(fajrOffset);
        }
        if (dhuhrOffset !== undefined) {
          updates.push('DhuhrOffset = ?');
          params.push(dhuhrOffset);
        }
        if (asrOffset !== undefined) {
          updates.push('AsrOffset = ?');
          params.push(asrOffset);
        }
        if (maghribOffset !== undefined) {
          updates.push('MaghribOffset = ?');
          params.push(maghribOffset);
        }
        if (ishaOffset !== undefined) {
          updates.push('IshaOffset = ?');
          params.push(ishaOffset);
        }

        if (updates.length === 0) {
          return {
            content: [
              {
                type: 'text',
                text: 'Warning: No offset values provided for update',
              } as TextContent,
            ],
          };
        }

        params.push(districtId);
        db.prepare(`UPDATE districts SET ${updates.join(', ')} WHERE DistrictID = ?`).run(...params);

        // Return updated record
        const updated = db
          .prepare('SELECT * FROM districts WHERE DistrictID = ?')
          .get(districtId) as DistrictRecord;

        return {
          content: [
            {
              type: 'text',
              text: JSON.stringify(
                {
                  success: true,
                  message: `District ${districtId} offsets updated successfully`,
                  district: updated,
                },
                null,
                2
              ),
            } as TextContent,
          ],
        };
      } finally {
        db.close();
      }
    } catch (e) {
      return {
        content: [
          {
            type: 'text',
            text: `Error updating district offsets: ${e instanceof Error ? e.message : 'unknown error'}`,
          } as TextContent,
        ],
        isError: true,
      };
    }
  },
  {
    readOnlyHint: false,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: false,
  }
);

// ====================
// Tool 7: Enterprise Search
// ====================

server.tool(
  'enterprise_search',
  'Search across all Fazilet ecosystem data: book content (FTS5), district records, and system logs. Returns ranked results with snippets.',
  {
    query: z
      .string()
      .min(2)
      .describe('Search query (2+ characters)'),
    scope: z
      .enum(['all', 'books', 'districts', 'logs'] as const)
      .default('all')
      .describe('Search scope: "all", "books", "districts", or "logs"'),
    limit: z
      .number()
      .int()
      .min(1)
      .max(100)
      .default(20)
      .describe('Max results per scope (default: 20)'),
  },
  async (args): Promise<CallToolResult> => {
    try {
      const { query, scope, limit } = args;
      const results: SearchResult[] = [];

      // Search books (FTS5)
      if (scope === 'all' || scope === 'books') {
        try {
          const files = await fs.readdir(BOOKS_DIR);
          for (const file of files) {
            if (!file.endsWith('.sqlite')) continue;
            try {
              const db = new Database(path.join(BOOKS_DIR, file));
              try {
                // Check if FTS5 table exists
                const ftsExists = db
                  .prepare(
                    "SELECT name FROM sqlite_master WHERE type='table' AND name='book_search'"
                  )
                  .get();
                if (ftsExists) {
                  const searchResults = db
                    .prepare(
                      `SELECT book_search.rowid, book_content.ChapterID, snippet(book_search, 0, '*', '*', '...', 16) as snippet
                       FROM book_search
                       JOIN book_content ON book_content.rowid = book_search.rowid
                       WHERE book_search MATCH ?
                       LIMIT ?`
                    )
                    .all(query, limit) as any[];

                  for (const r of searchResults) {
                    results.push({
                      type: 'book',
                      id: `${file}:${r.rowid}`,
                      title: file,
                      snippet: r.snippet ?? '...',
                      relevance: 1.0,
                    });
                  }
                }
              } finally {
                db.close();
              }
            } catch (bookError) {
              // Skip books that can't be searched
            }
          }
        } catch (e) {
          // Ignore book search errors
        }
      }

      // Search districts
      if (scope === 'all' || scope === 'districts') {
        try {
          const db = getDistrictsDb();
          try {
            const rows = db
              .prepare(
                'SELECT * FROM districts WHERE Name LIKE ? OR CityID LIKE ? LIMIT ?'
              )
              .all(`%${query}%`, `%${query}%`, limit) as DistrictRecord[];

            for (const row of rows) {
              results.push({
                type: 'district',
                id: `district-${row.DistrictID}`,
                title: row.Name,
                snippet: `${row.Name} (CityID: ${row.CityID}, Lat: ${row.Latitude}, Lon: ${row.Longitude})`,
                relevance: 0.9,
              });
            }
          } finally {
            db.close();
          }
        } catch (e) {
          // Ignore district search errors
        }
      }

      // Search logs
      if (scope === 'all' || scope === 'logs') {
        try {
          if (fsSync.existsSync(LOGS_DIR)) {
            const logFiles = await fs.readdir(LOGS_DIR);
            for (const logFile of logFiles.slice(0, 5)) {
              // Check last 5 log files
              if (!logFile.endsWith('.log')) continue;
              const logPath = path.join(LOGS_DIR, logFile);
              const content = await fs.readFile(logPath, 'utf-8');
              const lines = content.split('\n');
              for (let i = 0; i < lines.length; i++) {
                if (lines[i].toLowerCase().includes(query.toLowerCase())) {
                  results.push({
                    type: 'log',
                    id: `${logFile}:${i + 1}`,
                    title: logFile,
                    snippet: lines[i].substring(0, 200),
                    relevance: 0.7,
                  });
                  if (results.filter((r) => r.type === 'log').length >= limit) break;
                }
              }
            }
          }
        } catch (e) {
          // Ignore log search errors
        }
      }

      // Sort by relevance
      results.sort((a, b) => b.relevance - a.relevance);

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(
              {
                success: true,
                query,
                scope,
                count: results.length,
                results: results.slice(0, limit),
              },
              null,
              2
            ),
          } as TextContent,
        ],
      };
    } catch (e) {
      return {
        content: [
          {
            type: 'text',
            text: `Error performing enterprise search: ${e instanceof Error ? e.message : 'unknown error'}`,
          } as TextContent,
        ],
        isError: true,
      };
    }
  },
  {
    readOnlyHint: true,
    destructiveHint: false,
    idempotentHint: true,
    openWorldHint: true,
  }
);

// ====================
// Utility Functions
// ====================

async function generateChecksum(filePath: string): Promise<string> {
  const crypto = await import('crypto');
  const fileBuffer = await fs.readFile(filePath);
  return crypto.createHash('sha256').update(fileBuffer).digest('hex');
}

// ====================
// Server Startup
// ====================

async function main() {
  await ensureDirectories();

  // Validate districts database exists
  if (!fsSync.existsSync(DISTRICTS_DB_PATH)) {
    console.error(
      `ERROR: Districts database not found at ${DISTRICTS_DB_PATH}. ` +
        `Please create it with the schema from MASTER_PRD_ARCHITECTURE.md.`
    );
    process.exit(1);
  }

  const transport = new StandardMcpServerTransport();
  await server.connect(transport);
  console.error('Fazilet MCP Server running on stdio');
}

main().catch((error) => {
  console.error('Fatal error in main():', error);
  process.exit(1);
});
