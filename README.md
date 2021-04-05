# postgresql

https://github.com/pgexperts




# Executar comando sql pelo terminal
```
psql --host=$IP --port=$PORTA --username=$USUARIO --dbname=$NOME_BASE --no-password --command="$COMANDO_SQL"
```

# Exibir todos os parâmetros de runtime

```
SHOW config_file;

SELECT name, setting FROM pg_settings;

show all;
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

