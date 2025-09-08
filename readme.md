## Command ChangeAssembly

For this command must be the following requirements:

1. Create file `.projects` in the root command with the following structure:
```
BOOKING=C:\Repos\NS.Booking.Booking.API
PRICING=
CONTACTS=
FINANCE=
RESOURCE=
SERVICE=
UI=C:\Repos\NS.Booking.UI
WEB=C:\Repos\NS.Booking.Web
AMADEUS=C:\Repos\Amadeus.Soap-1.8
COVERGENIUS=C:\Repos\Covergenius-1.0
PROS=C:\Repos\PROS-2.0
```
**Note**: the path is depend where i have saved those projects and no matter the orden insert each line.

2. Create file `.filesPriority` in the root command with the following structure:
```
package.json
CustomWeb\CustomWeb.csproj
src\CustomLogic\Properties\AssemblyInfo.cs
src
```
**Note**: Here matter the orden insert each line and depends routes those `.csproj` or `.cs` or `.json`


For those use only must be execute the following on the powershell console:
```
.\ChangeAssembly.ps1 -NewVersion 2.13.0.0
```
