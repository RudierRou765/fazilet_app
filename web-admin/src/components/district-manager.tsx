import React, { useState, useMemo } from 'react';
import {
  useReactTable,
  getCoreRowModel,
  getFilteredRowModel,
  getPaginationRowModel,
  getSortedRowModel,
  flexRender,
  ColumnDef,
  SortingState,
} from '@tanstack/react-table';
import { mockDistricts, District } from '@/data/mock-districts';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Badge } from '@/components/ui/badge';
import {
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
  ArrowUpDown,
  ArrowUp,
  ArrowDown,
  Search,
} from 'lucide-react';
import { cn } from '@/lib/utils';

export function DistrictManager() {
  const [sorting, setSorting] = useState<SortingState>([]);
  const [globalFilter, setGlobalFilter] = useState('');
  const [columnVisibility, setColumnVisibility] = useState({});

  const columns = useMemo<ColumnDef<District, any>[]>(
    () => [
      {
        accessorKey: 'districtId',
        header: ({ column }) => (
          <Button
            variant="ghost"
            onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}
            className="font-heading text-xs font-semibold uppercase tracking-wider text-dark/50 hover:text-dark"
          >
            ID
            {column.getIsSorted() === 'asc' ? (
              <ArrowUp className="ml-2 h-4 w-4" />
            ) : column.getIsSorted() === 'desc' ? (
              <ArrowDown className="ml-2 h-4 w-4" />
            ) : (
              <ArrowUpDown className="ml-2 h-4 w-4" />
            )}
          </Button>
        ),
        cell: ({ row }) => (
          <span className="font-mono text-sm text-dark/70">
            {row.original.districtId}
          </span>
        ),
      },
      {
        accessorKey: 'name',
        header: ({ column }) => (
          <Button
            variant="ghost"
            onClick={() => column.toggleSorting(column.getIsSorted() === 'asc')}
            className="font-heading text-xs font-semibold uppercase tracking-wider text-dark/50 hover:text-dark"
          >
            District
            {column.getIsSorted() === 'asc' ? (
              <ArrowUp className="ml-2 h-4 w-4" />
            ) : column.getIsSorted() === 'desc' ? (
              <ArrowDown className="ml-2 h-4 w-4" />
            ) : (
              <ArrowUpDown className="ml-2 h-4 w-4" />
            )}
          </Button>
        ),
        cell: ({ row }) => (
          <div>
            <span className="font-heading font-medium text-dark">
              {row.original.name}
            </span>
            <p className="text-xs text-dark/50 font-body">
              {row.original.cityName}
            </p>
          </div>
        ),
      },
      {
        accessorKey: 'cityId',
        header: 'City ID',
        cell: ({ row }) => (
          <span className="font-mono text-sm text-dark/60">
            {row.original.cityId}
          </span>
        ),
      },
      {
        accessorKey: 'countryId',
        header: 'Country ID',
        cell: ({ row }) => (
          <span className="font-mono text-sm text-dark/60">
            {row.original.countryId}
          </span>
        ),
      },
      {
        accessorKey: 'latitude',
        header: 'Lat',
        cell: ({ row }) => (
          <span className="font-mono text-xs text-dark/60">
            {row.original.latitude.toFixed(4)}
          </span>
        ),
      },
      {
        accessorKey: 'longitude',
        header: 'Long',
        cell: ({ row }) => (
          <span className="font-mono text-xs text-dark/60">
            {row.original.longitude.toFixed(4)}
          </span>
        ),
      },
      {
        accessorKey: 'timeZone',
        header: 'Time Zone',
        cell: ({ row }) => (
          <Badge variant="outline" className="font-mono text-xs border-dark/20 text-dark/70">
            {row.original.timeZone}
          </Badge>
        ),
      },
      // Prayer Offsets
      {
        id: 'fajrOffset',
        header: () => (
          <span className="font-heading text-xs font-semibold uppercase text-accent-primary">
            Fajr
          </span>
        ),
        accessorFn: (row) => row.fajrOffset,
        cell: ({ row }) => (
          <span className="font-mono text-sm font-medium text-accent-primary">
            {row.original.fajrOffset}s
          </span>
        ),
      },
      {
        id: 'dhuhrOffset',
        header: () => (
          <span className="font-heading text-xs font-semibold uppercase text-accent-secondary">
            Dhuhr
          </span>
        ),
        accessorFn: (row) => row.dhuhrOffset,
        cell: ({ row }) => (
          <span className="font-mono text-sm font-medium text-accent-secondary">
            {row.original.dhuhrOffset}s
          </span>
        ),
      },
      {
        id: 'asrOffset',
        header: () => (
          <span className="font-heading text-xs font-semibold uppercase text-accent-tertiary">
            Asr
          </span>
        ),
        accessorFn: (row) => row.asrOffset,
        cell: ({ row }) => (
          <span className="font-mono text-sm font-medium text-accent-tertiary">
            {row.original.asrOffset}s
          </span>
        ),
      },
      {
        id: 'maghribOffset',
        header: () => (
          <span className="font-heading text-xs font-semibold uppercase text-dark/70">
            Maghrib
          </span>
        ),
        accessorFn: (row) => row.maghribOffset,
        cell: ({ row }) => (
          <span className="font-mono text-sm font-medium text-dark/70">
            {row.original.maghribOffset}s
          </span>
        ),
      },
      {
        id: 'ishaOffset',
        header: () => (
          <span className="font-heading text-xs font-semibold uppercase text-dark/70">
            Isha
          </span>
        ),
        accessorFn: (row) => row.ishaOffset,
        cell: ({ row }) => (
          <span className="font-mono text-sm font-medium text-dark/70">
            {row.original.ishaOffset}s
          </span>
        ),
      },
    ],
    []
  );

  const table = useReactTable({
    data: mockDistricts,
    columns,
    state: {
      sorting,
      globalFilter,
      columnVisibility,
    },
    onSortingChange: setSorting,
    onGlobalFilterChange: setGlobalFilter,
    onColumnVisibilityChange: setColumnVisibility,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
    getSortedRowModel: getSortedRowModel(),
  });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-heading text-2xl font-bold text-dark">
            District Manager
          </h1>
          <p className="mt-1 font-body text-sm text-dark/60">
            Manage 973 Turkey districts with Fazilet prayer time offsets
          </p>
        </div>
        <Badge className="bg-accent-primary/10 text-accent-primary border-accent-primary/20 font-heading">
          {mockDistricts.length} Districts Loaded
        </Badge>
      </div>

      {/* Table Controls */}
      <div className="flex items-center justify-between">
        <div className="relative w-72">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-dark/40" />
          <Input
            placeholder="Search districts..."
            value={globalFilter}
            onChange={(e) => setGlobalFilter(e.target.value)}
            className="pl-10 font-body border-dark/10 focus-visible:ring-accent-primary"
          />
        </div>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="outline" className="font-heading border-dark/10">
              Columns <ChevronDown className="ml-2 h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="font-body">
            {table
              .getAllColumns()
              .filter((column) => column.getCanHide())
              .map((column) => {
                const headerText =
                  typeof column.columnDef.header === 'string'
                    ? column.columnDef.header
                    : column.id;
                return (
                  <DropdownMenuCheckboxItem
                    key={column.id}
                    className="capitalize"
                    checked={column.getIsVisible()}
                    onCheckedChange={(value) =>
                      column.toggleVisibility(!!value)
                    }
                  >
                    {headerText}
                  </DropdownMenuCheckboxItem>
                );
              })}
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      {/* Data Table */}
      <div className="rounded-xl border border-dark/10 bg-white shadow-sm">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow
                key={headerGroup.id}
                className="border-dark/10 hover:bg-transparent"
              >
                {headerGroup.headers.map((header) => (
                  <TableHead
                    key={header.id}
                    className="whitespace-nowrap px-4 py-3.5"
                  >
                    {flexRender(
                      header.column.columnDef.header,
                      header.getContext()
                    )}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows.length ? (
              table.getRowModel().rows.map((row) => (
                <TableRow
                  key={row.id}
                  className="border-dark/5 transition-colors hover:bg-accent-primary/5"
                >
                  {row.getVisibleCells().map((cell) => (
                    <TableCell
                      key={cell.id}
                      className="px-4 py-3"
                    >
                      {flexRender(
                        cell.column.columnDef.cell,
                        cell.getContext()
                      )}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={columns.length}
                  className="h-24 text-center font-body text-dark/50"
                >
                  No districts found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>

      {/* Pagination */}
      <div className="flex items-center justify-between px-2">
        <div className="font-body text-sm text-dark/60">
          Showing{' '}
          <span className="font-medium text-dark">
            {table.getState().pagination.pageIndex *
              table.getState().pagination.pageSize +
              1}
          </span>{' '}
          to{' '}
          <span className="font-medium text-dark">
            {Math.min(
              (table.getState().pagination.pageIndex + 1) *
                table.getState().pagination.pageSize,
              table.getFilteredRowModel().rows.length
            )}
          </span>{' '}
          of{' '}
          <span className="font-medium text-dark">
            {table.getFilteredRowModel().rows.length}
          </span>{' '}
          districts
        </div>
        <div className="flex items-center space-x-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => table.setPageIndex(0)}
            disabled={!table.getCanPreviousPage()}
            className="font-heading border-dark/10"
          >
            <ChevronsLeft className="h-4 w-4" />
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => table.previousPage()}
            disabled={!table.getCanPreviousPage()}
            className="font-heading border-dark/10"
          >
            <ChevronLeft className="h-4 w-4" />
          </Button>
          <span className="font-heading text-sm text-dark/70 px-4">
            Page {table.getState().pagination.pageIndex + 1} of{' '}
            {table.getPageCount()}
          </span>
          <Button
            variant="outline"
            size="sm"
            onClick={() => table.nextPage()}
            disabled={!table.getCanNextPage()}
            className="font-heading border-dark/10"
          >
            <ChevronRight className="h-4 w-4" />
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => table.setPageIndex(table.getPageCount() - 1)}
            disabled={!table.getCanNextPage()}
            className="font-heading border-dark/10"
          >
            <ChevronsRight className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </div>
  );
}
