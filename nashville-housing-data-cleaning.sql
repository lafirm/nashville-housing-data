/*
Data Cleaning - Nashville Housing Dataset
*/

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

----------------------------------------------------------------------

--standardize date format
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

--UPDATE PortfolioProject.dbo.NashvilleHousing
--SET SaleDate = CONVERT(Date, SaleDate)
--> UPDATE function isn't working with existing column
--> let's try ALTER fn to create another column to use UPDATE function

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD SaleDateConverted Date;

UPDATE PortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDate, SaleDateConverted
FROM PortfolioProject.dbo.NashvilleHousing

----------------------------------------------------------------------

--populate property address data
SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL

--there are 29 rows with null values in property address
--let's try to find a way to populate those

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID

--check row 858-860, they all have same ParcelID, but 859 is missing property address
--let's get the address for NULL values in PropertyAddress column,
--by using JOINS on condition that ParcelID should be equal and UniqueID shouldn't be equal


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]		--unique ID shouldn't be equal
WHERE a.PropertyAddress IS NULL


--use ISNULL function to fill a.PropertyAddress with b.PropertyAddress
--a is alias for our original NashvilleHousing Table
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]		--unique ID shouldn't be equal
WHERE a.PropertyAddress IS NULL

----------------------------------------------------------------------

--breakdown address into individual columns(address, city, state)
SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing

--substring helps us to select the chars inside the string
--by taking args like column name, starting index, number of chars (positions)

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject.dbo.NashvilleHousing

--let's create a separate column for address and city to store the values

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD PropertySplitAddress nvarchar(255), PropertySplitCity nvarchar(255);
--columns created

UPDATE PortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

----------------------------------------------------------------------
--clean owner address column

SELECT OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing
WHERE OwnerAddress IS NOT NULL

--owner address has 3 values address, city and state
--let's use PARSENAME function to separate those instead of SUBSTRING

--PARSENAME works only with the '.' (dots / periods), so let's convert commas to dots to parse strings
SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.') ,3), --PARSENAME works backwards
PARSENAME(REPLACE(OwnerAddress,',','.') ,2),
PARSENAME(REPLACE(OwnerAddress,',','.') ,1)
FROM PortfolioProject.dbo.NashvilleHousing

--similar to PropertyAddress, let create new columns and store the values


ALTER TABLE PortfolioProject.dbo.NashvilleHousing
ADD OwnerSplitAddress nvarchar(255), OwnerSplitCity nvarchar(255), OwnerSplitState nvarchar(255) ;
--columns created

UPDATE PortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.') ,3),
OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.') ,2),
OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.') ,1)

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

----------------------------------------------------------------------

--visulaize SoldAsVacant column

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

--change Y & N to Yes & No in SoldAsVacant column
SELECT SoldAsVacant,
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
ELSE
	SoldAsVacant
END
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE PortfolioProject.dbo.NashvilleHousing
SET
SoldAsVacant = 
CASE
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
ELSE
	SoldAsVacant
END
--unlike our previous coding, update statement worked perfectly here w/o creating a new column


----------------------------------------------------------------------
--remove duplicates

--CTE is similar to a temp table
--create a CTE to add a column which indicates row number based on similarity in specified cond.
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject.dbo.NashvilleHousing
)

--row_num = 1 is original, row_num > 1 is duplicate
--show duplicate rows
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--delete duplicates **this snippet should come after CTE and should be executed along with CTE
--DELETE
--FROM RowNumCTE
--WHERE row_num > 1


----------------------------------------------------------------------
--delete unused columns

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict, SaleDate
