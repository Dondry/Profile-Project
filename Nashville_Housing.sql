/*

Cleaning the Nashville housing data

*/

select * from SolidProject.dbo.NashvilleHousing

---1. Standardize Date format
select SaleDate1
from SolidProject.dbo.NashvilleHousing

Alter Table SolidProject.dbo.NashvilleHousing
Add SaleDate1 Date;

update SolidProject..NashvilleHousing
Set SaleDate1 = CONVERT(Date, SaleDate)


---3. Populate Property Address Data

select Table1.ParcelID, Table1.PropertyAddress, Table2.ParcelID, Table2.PropertyAddress, ISNULL(table1.PropertyAddress, Table2.PropertyAddress)
from SolidProject.dbo.NashvilleHousing Table1
JOIN SolidProject.dbo.NashvilleHousing Table2
	ON Table1.ParcelID = Table2.ParcelID
	and Table1.[UniqueID ] <> Table2.[UniqueID ]
WHERE table1.PropertyAddress is null

update Table1
set Table1.PropertyAddress = isnull(table1.PropertyAddress, Table2.PropertyAddress)
from SolidProject.dbo.NashvilleHousing Table1
JOIN SolidProject.dbo.NashvilleHousing Table2
	ON Table1.ParcelID = Table2.ParcelID
	and Table1.[UniqueID ] <> Table2.[UniqueID ]
WHERE table1.PropertyAddress is null

---3. Breaking out Address into individual columns using Substring

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address, 
		SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(propertyAddress)) as City
		from SolidProject.dbo.NashvilleHousing

Alter Table SolidProject.dbo.NashvilleHousing
Add PorpertyAddress_Address Varchar(255);

update SolidProject..NashvilleHousing
Set PorpertyAddress_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) 

Alter Table SolidProject.dbo.NashvilleHousing
Add PropertyAddress_City Varchar(255);

update SolidProject..NashvilleHousing
Set PropertyAddress_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(propertyAddress))


---4. Breaking out Owner Address into individual columns using ParseName

Select
Parsename(replace(ownerAddress, ',', '.'), 3) as Address,
Parsename(replace(ownerAddress, ',', '.'), 2) as City,
Parsename(replace(ownerAddress, ',', '.'), 1) as State
from SolidProject..NashvilleHousing

Alter Table SolidProject.dbo.NashvilleHousing
Add OwnerAddress_Address Varchar(255);

update SolidProject..NashvilleHousing
set OwnerAddress_Address = Parsename(replace(ownerAddress, ',', '.'), 3)

Alter Table SolidProject.dbo.NashvilleHousing
Add OwnerAddress_City Varchar(255);

update SolidProject..NashvilleHousing
set OwnerAddress_City = Parsename(replace(ownerAddress, ',', '.'), 2)

Alter Table SolidProject.dbo.NashvilleHousing
Add OwnerAddress_State Varchar(255);

update SolidProject..NashvilleHousing
set OwnerAddress_State = Parsename(replace(ownerAddress, ',', '.'), 1) 



---5. in Sold as Vacant column replace Y with Yes and N with NO
select Distinct(soldasvacant),
CASE when soldasvacant = 'N' then 'No'
	when SoldAsVacant = 'Y' then 'Yes'
	Else SoldAsVacant
	end
from SolidProject..NashvilleHousing

update SolidProject..NashvilleHousing
set SoldAsVacant = CASE when soldasvacant = 'N' then 'No'
					when SoldAsVacant = 'Y' then 'Yes'
					Else SoldAsVacant
					end

-----6. Using CTE to delete duplicates
/* 
--------------6.1 Sorting out Duplicate

with RowNumber as (
select *, 
			ROW_NUMBER() OVER(
			Partition by ParcelID,
						PropertyAddress,
						SaleDate,
						SalePrice,
						LegalReference
			Order by UniqueID
)Row_num
from SolidProject.dbo.NashvilleHousing
)
DELETE
from RowNumber
WHERE Row_num > 1 
*/

---- 6.2 New Table without duplicates
with RowNumber as (
select *, 
			ROW_NUMBER() OVER(
			Partition by ParcelID,
						PropertyAddress,
						SaleDate,
						SalePrice,
						LegalReference
			Order by UniqueID
)Row_num
from SolidProject.dbo.NashvilleHousing
)
select *
from RowNumber

------ 7. Drop redundent columns
Select *
from SolidProject.dbo.NashvilleHousing

alter table SolidProject.dbo.NashvilleHousing
drop column propertyAddress, OwnerAddress, taxDistrict

alter table SolidProject.dbo.NashvilleHousing
drop column SaleDate