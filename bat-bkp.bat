SET PGUSER=postgres
SET PGPASSWORD=postgres
SET PGHOST=localhost
CLS
pg_dump -h localhost -p 5432 -U user -F c -b -v -f "C:\sistema\exe\..\backup\BKP_SISTEMA_20200330_155028.backup" db_finance
