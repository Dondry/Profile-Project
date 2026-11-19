/*

Cleaning the Nashville Housing Data
====================================

This script performs a complete data cleaning workflow on the NashvilleHousing
dataset in SQL Server. The cleaning steps are:

    1. Standardize the SaleDate format (convert to DATE type).
    2. Populate missing PropertyAddress values using self-joins.
    3. Split PropertyAddress into Address and City columns.
    4. Split OwnerAddress into Address, City, and State columns.
    5. Standardize the SoldAsVacant column (Y/N -> Yes/No).
    6. Identify and remove duplicate records.
    7. Drop redundant columns.
    8. Verify final data quality.
*/


-- ============================================================
-- 0. INITIAL DATA EXPLORATION
-- ============================================================

-- Preview the raw dataset
SELECT *
FROM SolidProject.dbo.NashvilleHousing;

-- Check row count and null distribution before cleaning
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN PropertyAddress IS NULL THEN 1 ELSE 0 END) AS NullPropertyAddress,
    SUM(CASE WHEN OwnerAddress IS NULL THEN 1 ELSE 0 END) AS NullOwnerAddress,
    SUM(CASE WHEN SaleDate IS NULL THEN 1 ELSE 0 END) AS NullSaleDate
FROM SolidProject.dbo.NashvilleHousing;


-- ============================================================
-- 1. STANDARDIZE DATE FORMAT
-- ============================================================

-- Inspect the original SaleDate column
SELECT SaleDate
FROM SolidProject.dbo.NashvilleHousing;

-- Add a new column to hold the converted date
ALTER TABLE SolidProject.dbo.NashvilleHousing
ADD SaleDate1 DATE;

-- Populate the new column with converted date values
UPDATE SolidProject.dbo.NashvilleHousing
SET SaleDate1 = CONVERT(DATE, SaleDate);

-- Verify the conversion
SELECT SaleDate, SaleDate1
FROM SolidProject.dbo.NashvilleHousing;


-- ============================================================
-- 2. POPULATE MISSING PROPERTY ADDRESS DATA
-- ============================================================

-- Inspect rows where PropertyAddress is null and find matching parcels
SELECT
    Table1.ParcelID,
    Table1.PropertyAddress,
    Table2.ParcelID,
    Table2.PropertyAddress,
    ISNULL(Table1.PropertyAddress, Table2.PropertyAddress) AS FilledAddress
FROM SolidProject.dbo.NashvilleHousing Table1
JOIN SolidProject.dbo.NashvilleHousing Table2
    ON Table1.ParcelID = Table2.ParcelID
    AND Table1.[UniqueID ] <> Table2.[UniqueID ]
WHERE Table1.PropertyAddress IS NULL;

-- Update null PropertyAddress values using the matching parcel's address
UPDATE Table1
SET Table1.PropertyAddress = ISNULL(Table1.PropertyAddress, Table2.PropertyAddress)
FROM SolidProject.dbo.NashvilleHousing Table1
JOIN SolidProject.dbo.NashvilleHousing Table2
    ON Table1.ParcelID = Table2.ParcelID
    AND Table1.[UniqueID ] <> Table2.[UniqueID ]
WHERE Table1.PropertyAddress IS NULL;

-- Verify no nulls remain
SELECT COUNT(*) AS RemainingNulls
FROM SolidProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL;


-- ============================================================
-- 3. BREAK OUT PROPERTY ADDRESS INTO INDIVIDUAL COLUMNS
-- ============================================================

-- Preview the split using SUBSTRING and CHARINDEX
SELECT
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM SolidProject.dbo.NashvilleHousing;

-- Add column for the street address
ALTER TABLE SolidProject.dbo.NashvilleHousing
ADD PropertyAddress_Address VARCHAR(255);

UPDATE SolidProject.dbo.NashvilleHousing
SET PropertyAddress_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

-- Add column for the city
ALTER TABLE SolidProject.dbo.NashvilleHousing
ADD PropertyAddress_City VARCHAR(255);

UPDATE SolidProject.dbo.NashvilleHousing
SET PropertyAddress_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Verify the split
SELECT PropertyAddress, PropertyAddress_Address, PropertyAddress_City
FROM SolidProject.dbo.NashvilleHousing;


-- ============================================================
-- 4. BREAK OUT OWNER ADDRESS INTO INDIVIDUAL COLUMNS
-- ============================================================

-- Preview the split using PARSENAME
SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM SolidProject.dbo.NashvilleHousing;

-- Add column for owner street address
ALTER TABLE SolidProject.dbo.NashvilleHousing
ADD OwnerAddress_Address VARCHAR(255);

UPDATE SolidProject.dbo.NashvilleHousing
SET OwnerAddress_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

-- Add column for owner city
ALTER TABLE SolidProject.dbo.NashvilleHousing
ADD OwnerAddress_City VARCHAR(255);

UPDATE SolidProject.dbo.NashvilleHousing
SET OwnerAddress_City = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

-- Add column for owner state
ALTER TABLE SolidProject.dbo.NashvilleHousing
ADD OwnerAddress_State VARCHAR(255);

UPDATE SolidProject.dbo.NashvilleHousing
SET OwnerAddress_State = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Verify the split
SELECT OwnerAddress, OwnerAddress_Address, OwnerAddress_City, OwnerAddress_State
FROM SolidProject.dbo.NashvilleHousing;


-- ============================================================
-- 5. STANDARDIZE "SOLD AS VACANT" COLUMN
-- ============================================================

-- Inspect distinct values
SELECT DISTINCT SoldAsVacant
FROM SolidProject.dbo.NashvilleHousing;

-- Count occurrences of each value
SELECT
    SoldAsVacant,
    COUNT(*) AS Count
FROM SolidProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY Count DESC;

-- Convert Y/N to Yes/No
UPDATE SolidProject.dbo.NashvilleHousing
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 'N' THEN 'No'
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    ELSE SoldAsVacant
END;

-- Verify standardization
SELECT DISTINCT SoldAsVacant
FROM SolidProject.dbo.NashvilleHousing;


-- ============================================================
-- 6. REMOVE DUPLICATES
-- ============================================================

-- 6.1 Identify duplicates before deleting
WITH RowNumber AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
                         PropertyAddress,
                         SaleDate,
                         SalePrice,
                         LegalReference
            ORDER BY UniqueID
        ) AS Row_num
    FROM SolidProject.dbo.NashvilleHousing
)
SELECT *
FROM RowNumber
WHERE Row_num > 1;

-- 6.2 create a new table without duplicates
WITH RowNumber AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
                         PropertyAddress,
                         SaleDate,
                         SalePrice,
                         LegalReference
            ORDER BY UniqueID
        ) AS Row_num
    FROM SolidProject.dbo.NashvilleHousing
)
SELECT *
INTO SolidProject.dbo.NashvilleHousing_Clean
FROM RowNumber
WHERE Row_num = 1;

-- ============================================================
-- 7. DROP REDUNDANT COLUMNS
-- ============================================================

-- Preview the current table structure
SELECT *
FROM SolidProject.dbo.NashvilleHousing;

-- Drop the original composite address columns
ALTER TABLE SolidProject.dbo.NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict;

-- Drop the original SaleDate column
ALTER TABLE SolidProject.dbo.NashvilleHousing
DROP COLUMN SaleDate;

-- Verify the final table structure
SELECT *
FROM SolidProject.dbo.NashvilleHousing;


-- ============================================================
-- 8. FINAL DATA QUALITY VERIFICATION
-- ============================================================

-- Confirm no nulls remain in critical columns
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN PropertyAddress_Address IS NULL THEN 1 ELSE 0 END) AS NullPropertyAddress,
    SUM(CASE WHEN OwnerAddress_Address IS NULL THEN 1 ELSE 0 END) AS NullOwnerAddress,
    SUM(CASE WHEN SaleDate1 IS NULL THEN 1 ELSE 0 END) AS NullSaleDate,
    SUM(CASE WHEN SoldAsVacant NOT IN ('Yes', 'No') THEN 1 ELSE 0 END) AS InvalidSoldAsVacant
FROM SolidProject.dbo.NashvilleHousing;

-- Confirm no duplicate UniqueIDs remain
SELECT UniqueID, COUNT(*) AS Occurrences
FROM SolidProject.dbo.NashvilleHousing
GROUP BY UniqueID
HAVING COUNT(*) > 1;
