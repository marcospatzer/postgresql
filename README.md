
## Terminal
```
psql --host=$IP --port=$PORTA --username=$USUARIO --dbname=$NOME_BASE --no-password --command="$COMANDO_SQL"
```

## Info
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


-- Vacuum and Analyze info
SELECT
  schemaname,
  relname,
  n_live_tup,
  n_dead_tup,
  n_dead_tup / GREATEST(n_live_tup + n_dead_tup, 1)::float * 100 AS dead_percentage,
  n_mod_since_analyze,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze,
  vacuum_count,
  autovacuum_count,
  analyze_count,
  autoanalyze_count
FROM
  pg_stat_user_tables
ORDER BY
  n_dead_tup DESC,
  n_mod_since_analyze DESC,
  last_vacuum DESC,
  last_analyze DESC,
  last_autovacuum DESC,
  last_autoanalyze DESC;
    
```
  
  
## show parameters

```
SHOW config_file;

SELECT name, setting FROM pg_settings;

show all;
```

## databases by size descending
```
SELECT
  datname,
  pg_size_pretty(pg_database_size(datname))
FROM
  pg_database
ORDER
  BY pg_database_size(datname) DESC;
```

## Running queries
```
SELECT
  pid,
  age(clock_timestamp(), query_start),
  usename,
  application_name,
  query
FROM
  pg_stat_activity
WHERE
  state != 'idle'
    AND
  query NOT ILIKE '%pg_stat_activity%'
ORDER BY
  query_start DESC;
```
  

## Lists queries blocked along with the pids of those holding the locks blocking them
```
-- Requires PostgreSQL >= 9.6
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

## Indexes Cache-hit Ratio (should be closer to 1, eg. 0.99)
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


## Locks
```
SELECT
  t.schemaname,
  t.relname,
  -- l.database, -- id number is less useful, take schemaname from join instead
  l.locktype,
  page,
  virtualtransaction,
  pid,
  mode,
  granted
FROM
  pg_locks l,
  --pg_stat_user_tables t
  pg_stat_all_tables t
WHERE
  l.relation = t.relid
ORDER BY
  relation ASC;

SELECT
  relation::regclass AS relation_regclass,
  *
FROM
  pg_locks
WHERE
  NOT granted;
```


## Locks Blocked
```
SELECT
  blocked_locks.pid         AS blocked_pid,
  blocked_activity.usename  AS blocked_user,
  blocking_locks.pid        AS blocking_pid,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query    AS blocked_statement,
  blocking_activity.query   AS current_statement_in_blocking_process
FROM
  pg_catalog.pg_locks AS blocked_locks
JOIN
  pg_catalog.pg_stat_activity AS blocked_activity
ON
  blocked_activity.pid = blocked_locks.pid
JOIN
  pg_catalog.pg_locks AS blocking_locks
ON
  blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.database       IS NOT DISTINCT FROM blocked_locks.database
  AND blocking_locks.relation       IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.page           IS NOT DISTINCT FROM blocked_locks.page
  AND blocking_locks.tuple          IS NOT DISTINCT FROM blocked_locks.tuple
  AND blocking_locks.virtualxid     IS NOT DISTINCT FROM blocked_locks.virtualxid
  AND blocking_locks.transactionid  IS NOT DISTINCT FROM blocked_locks.transactionid
  AND blocking_locks.classid        IS NOT DISTINCT FROM blocked_locks.classid
  AND blocking_locks.objid          IS NOT DISTINCT FROM blocked_locks.objid
  AND blocking_locks.objsubid       IS NOT DISTINCT FROM blocked_locks.objsubid
  AND blocking_locks.pid != blocked_locks.pid
JOIN
  pg_catalog.pg_stat_activity blocking_activity
ON
  blocking_activity.pid = blocking_locks.pid
WHERE
  NOT blocked_locks.granted;
```
  
## SLOW: queries currently executing that have taken over 30 secs
```
-- Requires 9.2 <= PostgreSQL <= 9.5
SELECT
  now() - query_start as "runtime",
  usename,
  datname,
  -- not available on PostgreSQL < 9.6
  -- wait_event,
  waiting,
  -- not available on PostgreSQL < 9.2
  state,
  query
FROM
  pg_stat_activity
WHERE
  -- can't use 'runtime' here
  now() - query_start > '30 seconds'::interval
ORDER BY
  runtime DESC;
  
-- PostgreSQL 9.6+, 10x, 11.x, 12.x, 13.0  
SELECT
  now() - query_start as "runtime",
  usename,
  datname,
  -- not available on PostgreSQL < 9.6
  wait_event,
  -- not available on PostgreSQL < 9.2
  state,
  -- current_query on PostgreSQL < 9.2
  query
FROM
  pg_stat_activity
WHERE
  -- can't use 'runtime' here
  now() - query_start > '30 seconds'::interval
ORDER BY
  runtime DESC;
```

## locks with query and age
```
SELECT
  a.datname,
  l.relation::regclass,
  l.transactionid,
  l.mode,
  l.GRANTED,
  a.usename,
  a.query,
  a.query_start,
  age(now(), a.query_start) AS "age",
  a.pid
FROM
  pg_stat_activity a
JOIN
  pg_locks l
ON
  l.pid = a.pid
ORDER BY
  a.query_start;
```


## Queries cache-hit ratio from pg_stat_statements
```
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SELECT
  calls,
  rows,
  shared_blks_hit,
  shared_blks_read,
  -- using greatest() to avoid divide by zero error, by ensuring we divide by at least 1
    shared_blks_hit /
    GREATEST(shared_blks_hit + shared_blks_read, 1)::float AS shared_blks_hit_ratio,
    -- casting divisor to float to avoid getting integer maths returning zeros instead of fractional ratios
  local_blks_hit,
  local_blks_read,
    local_blks_hit /
    GREATEST(local_blks_hit + local_blks_read, 1)::float AS local_blks_hit_ratio,
  query
FROM
  pg_stat_statements
--ORDER BY rows DESC
ORDER BY
  shared_blks_hit_ratio DESC,
  local_blks_hit_ratio DESC,
  rows DESC
LIMIT 100;
```

## Script
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

## EXPLAIN

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






https://github.com/pgexperts

https://pgbadger.darold.net/

https://pgtune.leopard.in.ua/#/

https://github.com/jfcoz/postgresqltuner


