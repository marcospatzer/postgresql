# postgresql

https://github.com/pgexperts




# Executar comando sql pelo terminal
```
psql --host=$IP --port=$PORTA --username=$USUARIO --dbname=$NOME_BASE --no-password --command="$COMANDO_SQL"
```

# Info
```
--'PostgreSQL Version'
SELECT
  version(),
  current_setting('server_version') AS "server_version",
  current_setting('server_version_num') AS "server_version_num";
  
--'Config Files'  
SELECT
  current_setting('config_file') AS "config_file",
  current_setting('hba_file') AS "hba_file",
  current_setting('ident_file') AS "ident_file";

-- 'PostgreSQL Data Directory & Unix Sockets'
SELECT
  current_setting('data_directory') AS "data_directory",
  current_setting('unix_socket_directories') AS "unix_socket_directories",
  current_setting('unix_socket_permissions') AS "unix_socket_permissions",
  current_setting('unix_socket_group') AS "unix_socket_group";
  
  
-- 'Buffers & Connections'
SELECT
  current_setting('shared_buffers') AS "shared_buffers",
  current_setting('work_mem') AS "work_mem",
  current_setting('max_connections') AS "max_connections",
  current_setting('max_files_per_process') AS "max_files_per_process", -- should be less than ulimit nofiles to avoid “Too many open files” failures
  current_setting('track_activities') AS "track_activities", -- for pg_stat / pg_statio family of system views that are used in many other adjacent scripts
  current_setting('track_counts') AS "track_counts", -- needed for the autovacuum daemon
  current_setting('password_encryption') AS "password_encryption";


-- Analyze info for tables with rows modified since last analyze
SELECT
  schemaname,
  relname,
  -- not available on PostgreSQL <= 9.3
  n_mod_since_analyze,
  last_analyze,
  last_autoanalyze,
  -- not available on PostgreSQL <= 9.0
  analyze_count,
  autoanalyze_count
FROM pg_stat_user_tables
ORDER BY
  n_mod_since_analyze DESC,
  last_analyze DESC,
  last_autoanalyze DESC;
    
```
  
  
# Exibir todos os parâmetros de runtime

```
SHOW config_file;

SELECT name, setting FROM pg_settings;

show all;
```

# PostgreSQL databases by size descending
```
SELECT
  datname,
  pg_size_pretty(pg_database_size(datname))
FROM
  pg_database
ORDER
  BY pg_database_size(datname) DESC;
```


# Lists queries blocked along with the pids of those holding the locks blocking them
-- Requires PostgreSQL >= 9.6
```
SELECT
  pid,
  usename,
  pg_blocking_pids(pid) AS blocked_by_pids,
  query AS blocked_query
FROM
  pg_stat_activity
WHERE
  cardinality(pg_blocking_pids(pid)) > 0;
```

# Indexes Cache-hit Ratio
-- should be closer to 1, eg. 0.99
```
SELECT
  SUM(idx_blks_read) AS idx_blks_read,
  SUM(idx_blks_hit)  AS idx_blks_hit,
           SUM(idx_blks_hit) /
  GREATEST(SUM(idx_blks_hit) + SUM(idx_blks_read), 1)::float
              AS ratio
FROM
  pg_statio_user_indexes;
```

# Script
```
DO
$$
declare
x record;
BEGIN
  delete from tb_cdbar;
  For x in (select a.id_produ, 
                   replace(a.codigo_produ,'.','') as codigo
              from tb_produ a
             where a.cmatven = 'R') 
  loop
    insert Into tb_cdbar (nnumerocdbar, 
                          nnumeroprodu, 
                          nquanticdbar)
                  values (cast(x.codigo as bigint), 
                          x.id_produ, 
                          1); 
  End Loop; 
END
$$;
```

# EXPLAIN

O PostgreSQL dá um relatório completo da execução da query.
Para vê-lo execute a consulta assim:

```
EXPLAIN ANALYSE SELECT * FROM foo;

                       QUERY PLAN
---------------------------------------------------------
"Seq Scan on foo  (cost=0.00..2.62 rows=62 width=226) (actual time=0.011..0.020 rows=62 loops=1)"
"Total runtime: 0.059 ms"

```
Dependendo da complexidade da consulta, o resultado fica bem difícil de entender.

Colando o resultado neste site: 

https://explain.depesz.com/

fica mais fácil de entender. 
Ele deixa de um jeito mais fácil de ler, destaca os pontos críticos e dá algumas estatísticas do relatório mais resumidas e legíveis.

Alguns exemplos de análises de sqls Exemplos-depesz
https://explain.depesz.com/history




# Comando Execute para Dinamismo no Postgresql
Basicamente: Usar sql e concatenação de texto para construir outras sqls, e então executá-las no banco com o auxílio da função EXECUTE 
(disponível apenas dentro de function's ou procedure's).

O exemplo abaixo fala por si só.
Criação de uma função simples:

```
CREATE OR REPLACE FUNCTION qtd(nomeTabela text) RETURNS integer LANGUAGE plpgsql AS $$
DECLARE
    resultado integer;
BEGIN
    EXECUTE 'SELECT count(1) FROM ' || nomeTabela INTO resultado;
    RETURN resultado;
END; $$;

Uso da função:

SELECT qtd('tabela_estoque');
SELECT qtd('tabela_produtos');

Outro uso exemplo:


CREATE OR REPLACE FUNCTION dropConstraint(nomeTabela text, nomeConstraint text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE 'ALTER TABLE ' || nomeTabela || ' DROP CONSTRAINT ' || nomeConstraint;
END; $$;
```
A partir dai, é sua necessidade e capacidade de construção de functions para fazer o que você precisa.







https://pgbadger.darold.net/

https://pgtune.leopard.in.ua/#/

