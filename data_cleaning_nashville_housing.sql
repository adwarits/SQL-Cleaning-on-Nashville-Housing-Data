-- DATABASE CLEANING SQL

USE project_portfolio

-- 1. LOOKING INTO CURRENT DATA AND CHANGING DATA FORMAT

SELECT *
FROM dbo.NashvilleHousingData

-- Switch Data Type from TEXT to VARCHAR

ALTER TABLE dbo.nashvillehousingdata ALTER COLUMN ParcelID VARCHAR(MAX)
ALTER TABLE dbo.nashvillehousingdata ALTER COLUMN LandUse VARCHAR(MAX)
ALTER TABLE dbo.nashvillehousingdata ALTER COLUMN PropertyAddress VARCHAR(MAX)
ALTER TABLE dbo.nashvillehousingdata ALTER COLUMN LegalReference VARCHAR(MAX)
ALTER TABLE dbo.nashvillehousingdata ALTER COLUMN SoldAsVacant VARCHAR(MAX)
ALTER TABLE dbo.nashvillehousingdata ALTER COLUMN OwnerName VARCHAR(MAX)
ALTER TABLE dbo.nashvillehousingdata ALTER COLUMN OwnerAddress VARCHAR(MAX)
ALTER TABLE dbo.nashvillehousingdata ALTER COLUMN TaxDistrict VARCHAR(MAX)

-- 2. POPULATING PROPERTY ADDRESS

-- Fill the blank data with NULL

UPDATE dbo.NashvilleHousingData
SET PropertyAddress = NULL
WHERE PropertyAddress = ' '

-- Find the root cause of why there are null in PropertyAddress or not

SELECT 
    a.UniqueID, 
    b.UniqueID, 
    a.ParcelID, 
    b.ParcelID, 
    a.PropertyAddress, 
    b.PropertyAddress, 
    ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NashvilleHousingData AS a 
JOIN dbo.NashvilleHousingData AS b 
ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL


-- Insight: no rows have the same UniqueID, but there are rows that have the same ParcelID
-- They left the PropertyAddress null because they already have the same data before. They only wrote its ParcelID
-- Fill in the null PropertyAddress

UPDATE a 
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM dbo.NashvilleHousingData AS a 
JOIN dbo.NashvilleHousingData AS b 
ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

-- 3. BREAKING OUT PROPERTY ADDRESS

SELECT PropertyAddress
FROM dbo.NashvilleHousingData

-- Seperate the city from the property address
-- The city is located at last part after the comma on PropertyAddress

SELECT SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)-CHARINDEX(',', PropertyAddress)+1) AS PropertyAddressCity
FROM dbo.NashvilleHousingData

ALTER TABLE dbo.NashvilleHousingData
ADD PropertyAddressCity VARCHAR(MAX)

UPDATE dbo.NashvilleHousingData
SET PropertyAddressCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)-CHARINDEX(',', PropertyAddress)+1)

-- Split the owner address

SELECT
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) + ',' +
    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM dbo.NashvilleHousingData

ALTER TABLE dbo.NashvilleHousingData
ADD OwnerCityAddress VARCHAR(MAX)

UPDATE dbo.NashvilleHousingData
SET OwnerCityAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) + 
                    ',' +
                    PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM dbo.NashvilleHousingData

-- 4. CHANGE Y AND N TO YES AND NO IN SOLDASVACANT

-- Looking at various data in SoldAsVacant which has similiar meeting

SELECT 
    SoldAsVacant, 
    COUNT(SoldAsVacant) AS Total
FROM dbo.NashvilleHousingData
GROUP BY SoldAsVacant
ORDER BY Total

-- Insight: In SoldAsVacant, Y similiar to Yes and N to No
-- Switch Y to Yes and N to No

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END AS SoldAsVacant
FROM dbo.NashvilleHousingData

UPDATE dbo.NashvilleHousingData
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
                WHEN SoldAsVacant = 'N' THEN 'No'
                ELSE SoldAsVacant
                END

-- 5. REMOVE DUPLICATES

-- Looking at duplicate rows

WITH RowNumCTE AS (
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
        ORDER BY UniqueID) row_num
        FROM dbo.NashvilleHousingData
        )
SELECT *
FROM RowNumCTE
WHERE row_num > 1

-- Delete duplicate rows

WITH RowNumCTE AS (
    SELECT *,
    ROW_NUMBER() OVER (
        PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
        ORDER BY UniqueID) row_num
        FROM dbo.NashvilleHousingData
        )
DELETE 
FROM RowNumCTE
WHERE row_num > 1

