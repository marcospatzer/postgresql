SET PGUSER=postgres
SET PGPASSWORD=senha123
SET PGHOST=192.168.200.101
CLS
psql -h 192.168.200.101 -p 5432 -U postgres --file=troca_senha_suporte.txt db_sistema
 -v  -z  -f  -p 5432 db_sistema
 -Z  -p 5432 db_sistema

psql -h 192.168.200.101 -p 5432 -U postgres --file=troca_senha.txt db_sistema
del "D:\Suporte\troca_senha.TXT"
del "D:\Suporte\troca_senha_suporte.TXT"
timeout /t -1
