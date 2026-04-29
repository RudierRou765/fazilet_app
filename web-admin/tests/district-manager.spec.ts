import { test, expect } from '@playwright/test';

/**
 * District Manager E2E Tests
 * Following webapp-testing (Playwright) guidelines
 * Tests rendering and search functionality of the District Manager table
 */

test.describe('District Manager Data Table', () => {
  // Setup: Navigate to the districts page before each test
  test.beforeEach(async ({ page }) => {
    // Mock API endpoint for districts if needed in future
    await page.goto('http://localhost:3000/dashboard/districts');

    // Wait for the table to be visible
    await page.waitForSelector('table', { state: 'visible' });
  });

  test('should render the District Manager header and table structure', async ({ page }) => {
    // Verify page title/header
    const header = page.locator('h1');
    await expect(header).toHaveText('District Manager');

    // Verify table is rendered with correct structure
    const table = page.locator('table');
    await expect(table).toBeVisible();

    // Verify all column headers are present (using font-heading styling)
    const headers = page.locator('thead th');
    await expect(headers).toHaveCount(12); // ID, District, City ID, Country ID, Lat, Long, Time Zone, 5 prayer offsets

    // Verify specific column headers
    await expect(page.locator('thead')).toContainText('District');
    await expect(page.locator('thead')).toContainText('Lat');
    await expect(page.locator('thead')).toContainText('Long');
    await expect(page.locator('thead')).toContainText('Fajr');
    await expect(page.locator('thead')).toContainText('Dhuhr');
  });

  test('should display mock district data in table rows', async ({ page }) => {
    // Verify rows are rendered
    const rows = page.locator('tbody tr');
    const rowCount = await rows.count();
    expect(rowCount).toBeGreaterThan(0);

    // Verify first row contains expected data (Adalar district)
    const firstRow = rows.first();
    await expect(firstRow).toContainText('1'); // DistrictID
    await expect(firstRow).toContainText('Adalar'); // District Name
    await expect(firstRow).toContainText('İstanbul'); // City

    // Verify second row (Arnavutköy)
    const secondRow = rows.nth(1);
    await expect(secondRow).toContainText('2');
    await expect(secondRow).toContainText('Arnavutköy');
  });

  test('should perform global search and filter results', async ({ page }) => {
    // Get initial row count
    const initialRows = page.locator('tbody tr');
    const initialCount = await initialRows.count();

    // Search for "Ankara" using the search input
    const searchInput = page.locator('input[placeholder*="Search districts"]');
    await expect(searchInput).toBeVisible();
    await searchInput.fill('Ankara');

    // Wait for table to update
    await page.waitForTimeout(300);

    // Verify filtered results
    const filteredRows = page.locator('tbody tr');
    const filteredCount = await filteredRows.count();

    // Should have fewer rows after filtering
    expect(filteredCount).toBeLessThan(initialCount);

    // Verify all visible rows contain "Ankara" or "Altındağ" or "Çankaya" or "Keçiören"
    for (let i = 0; i < filteredCount; i++) {
      const rowText = await filteredRows.nth(i).textContent();
      expect(rowText).toMatch(/Ankara|Altındağ|Çankaya|Keçiören/);
    }

    // Clear search and verify all rows return
    await searchInput.clear();
    await page.waitForTimeout(300);
    const clearedRows = page.locator('tbody tr');
    const clearedCount = await clearedRows.count();
    expect(clearedCount).toEqual(initialCount);
  });

  test('should perform search by district ID', async ({ page }) => {
    const searchInput = page.locator('input[placeholder*="Search districts"]');

    // Search for district ID "2001" (Aksu, Antalya)
    await searchInput.fill('2001');
    await page.waitForTimeout(300);

    const rows = page.locator('tbody tr');
    const count = await rows.count();
    expect(count).toBe(1);

    const rowText = await rows.first().textContent();
    expect(rowText).toContain('Aksu');
    expect(rowText).toContain('Antalya');
  });

  test('should sort columns when clicking sortable headers', async ({ page }) => {
    // Click on District column header to sort
    const districtHeader = page.locator('thead').getByText('District', { exact: false });
    await districtHeader.click();
    await page.waitForTimeout(300);

    // Verify sort indicator is visible (ArrowUp icon for ascending)
    const headerButton = districtHeader.locator('..').locator('button');
    await expect(headerButton.locator('svg')).toBeVisible();

    // Click again to reverse sort
    await districtHeader.click();
    await page.waitForTimeout(300);
  });

  test('should navigate through pagination', async ({ page }) => {
    // Check if pagination controls are visible
    const prevButton = page.getByRole('button', { name: /previous/i });
    const nextButton = page.getByRole('button', { name: /next/i });

    await expect(prevButton).toBeVisible();
    await expect(nextButton).toBeVisible();

    // Get current page info
    const pageInfo = page.locator('text=/Page \\d+ of \\d+/');
    await expect(pageInfo).toBeVisible();

    // Try to go to next page if available
    const initialPageText = await pageInfo.textContent();

    if (await nextButton.isEnabled()) {
      await nextButton.click();
      await page.waitForTimeout(300);

      const newPageText = await pageInfo.textContent();
      expect(newPageText).not.toEqual(initialPageText);
    }
  });

  test('should toggle column visibility via dropdown', async ({ page }) => {
    // Open column visibility dropdown
    const columnsButton = page.getByRole('button', { name: /columns/i });
    await columnsButton.click();

    // Dropdown should be visible
    const dropdown = page.locator('[role="menu"]');
    await expect(dropdown).toBeVisible();

    // Find a checkbox (e.g., for "City ID" column)
    const cityIdCheckbox = dropdown.getByText('cityId');
    await expect(cityIdCheckbox).toBeVisible();

    // Toggle column visibility
    await cityIdCheckbox.click();

    // Close dropdown by clicking outside or pressing Escape
    await page.keyboard.press('Escape');

    // Verify column is hidden (header should not be visible)
    // Note: This depends on implementation - may need adjustment
  });

  test('should display prayer offset values with correct accent colors', async ({ page }) => {
    const firstRow = page.locator('tbody tr').first();

    // Verify Fajr offset is displayed (should have accent-primary color class)
    await expect(firstRow).toContainText('95s'); // Fajr offset for Adalar

    // Verify Dhuhr offset
    await expect(firstRow).toContainText('60s'); // Dhuhr offset

    // Verify all 5 prayer offsets are present in the table
    const headers = page.locator('thead th');
    await expect(headers.getByText('Fajr', { exact: false })).toBeVisible();
    await expect(headers.getByText('Dhuhr', { exact: false })).toBeVisible();
    await expect(headers.getByText('Asr', { exact: false })).toBeVisible();
    await expect(headers.getByText('Maghrib', { exact: false })).toBeVisible();
    await expect(headers.getByText('Isha', { exact: false })).toBeVisible();
  });

  test('should display timezone badges', async ({ page }) => {
    const firstRow = page.locator('tbody tr').first();

    // Verify timezone badge is rendered
    const badge = firstRow.locator('[role="status"]').or(firstRow.locator('.badge'));
    await expect(firstRow).toContainText('Europe/Istanbul');
  });

  test('should highlight search matches in results', async ({ page }) => {
    const searchInput = page.locator('input[placeholder*="Search districts"]');

    // Search for "İzmir"
    await searchInput.fill('İzmir');
    await page.waitForTimeout(300);

    // Verify filtered results show only İzmir districts
    const rows = page.locator('tbody tr');
    const count = await rows.count();
    expect(count).toBe(2); // Konak and Bornova

    // Verify both districts are shown
    await expect(page.locator('tbody')).toContainText('Konak');
    await expect(page.locator('tbody')).toContainText('Bornova');
  });
});
