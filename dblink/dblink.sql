CREATE EXTENSION dblink;

SELECT dblink_connect('Sistema - Cliente'::text,'hostaddr=187.175.46.13 port=5432 dbname=db_sistema user=postgres password=senha'::text);

SELECT * FROM dblink('Sistema - Cliente','SELECT cnomeempre FROM empresas') AS t(nome varchar)



SELECT * FROM dblink('cliente1','SELECT cnomeempre FROM empresas') AS t(nome varchar)
union all
SELECT * FROM dblink('cliente2','SELECT cnomeempre FROM empresas') AS t(nome varchar)



xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

--Consultando conexões abertas com DBLINK
SELECT dblink_get_connections();

--Desconexão
SELECT dblink_disconnect('cliente1');
SELECT dblink_disconnect('cliente2');

/*
As principais funções do dblink são:
- dblink_connect
- dblink_get_connections
- dblink - para consultas
- dblink_exec - utilizado na inserção, alteração e exclusão de dados
- dblink_disconnect - liberar conexões dblink
*/


xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

DO
$$

DECLARE
   r1   record;

BEGIN
	FOR r1 IN (
		SELECT a.descricao,
               'host='||a.ip||' port='||a.porta||' dbname='||a.database||' user=usuario password=senha' as conexao
          FROM sisbases a
         WHERE a.tipo = 'M'
           AND (
                 (a.descricao = 'M - Cliente1')
                 OR
                 (a.descricao = 'M - Cliente2')
                 OR
                 (a.descricao = 'M - Cliente3')
               )
	)
	LOOP
		BEGIN
			PERFORM dblink_connect(r1.descricao, r1.conexao);
		EXCEPTION
      		WHEN others THEN
         		RAISE NOTICE '% (%)', SQLERRM, r1.descricao;
		END;
	END LOOP;

    CREATE TEMPORARY TABLE conexoes_dblink as
      WITH links AS (SELECT unnest(dblink_get_connections()) AS descricao)
                     SELECT a.descricao, (b.descricao IS NOT NULL) AS OK
                       FROM sisbases a LEFT OUTER JOIN links b ON a.descricao = b.descricao
                      WHERE a.tipo = 'M'
       AND (
              (a.descricao = 'M - Cliente1')
              OR
              (a.descricao = 'M - Cliente2')
              OR
              (a.descricao = 'M - Cliente3')
           );
END;
$$;

SELECT a.*,
       CASE WHEN a.ok THEN
       	(SELECT * FROM dblink(a.descricao,'SELECT COUNT(ta.*) FROM tb_usuar ta') AS t(usuarios integer))
       END AS usuarios
  FROM conexoes_dblink a;
  
  
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx


ODBC para PBI:
--------------

https://www.postgresql.org/ftp/odbc/versions/msi/

  
  
CREATE DATABASE powerbi
  WITH OWNER = postgres
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       LC_COLLATE = 'Portuguese, Brazil'
       LC_CTYPE = 'Portuguese, Brazil'
       CONNECTION LIMIT = -1;


	   
CREATE TABLE public.tipo_pedido_venda (
  id_tipo_pedido_venda BIGINT NOT NULL,
  descricao VARCHAR(100),
  gera_estoque CHAR(1),
  gera_financeiro CHAR(1),
  venda CHAR(1)
) 
WITH (oids = false);

CREATE TABLE public.empresas (
  id_empresa BIGINT NOT NULL,
  razao VARCHAR(100) NOT NULL,
  fantasia VARCHAR(100) NOT NULL
) 
WITH (oids = false);


CREATE TABLE public.faturamento (
  id_empresa BIGINT NOT NULL,
  id_faturamento BIGINT NOT NULL,
  id_cliente BIGINT NOT NULL,
  id_tipo_pedido_venda BIGINT NOT NULL,
  demi_b09 DATE NOT NULL,
  nnf_b08 BIGINT NOT NULL,
  nome_cidade_destinatario VARCHAR(100),
  uf_e12 VARCHAR(2),
  nome_pais_destinatario CHAR(20),
  vbc_w03 NUMERIC,
  vicms_w04 NUMERIC,
  vbcst_w05 NUMERIC,
  vst_w06 NUMERIC,
  vipi_w12 NUMERIC,
  vpis_w13 NUMERIC,
  vcofins_w14 NUMERIC,
  voutro_w15 NUMERIC,
  vprod_w07 NUMERIC,
  vfrete_w08 NUMERIC,
  vseg_w09 NUMERIC,
  vdesc_w10 NUMERIC,
  vnf_w16 NUMERIC
) 
WITH (oids = false);


CREATE TABLE public.tipo_pedido_venda (
  id_tipo_pedido_venda BIGINT NOT NULL,
  descricao VARCHAR(100),
  gera_estoque CHAR(1),
  gera_financeiro CHAR(1),
  venda CHAR(1)
) 
WITH (oids = false);



CREATE OR REPLACE FUNCTION public.prc_power_bi (
)
RETURNS void AS
$body$
declare

x          record;

BEGIN
  BEGIN
    PERFORM dblink_connect('nome_cliente', 
                           'hostaddr=195.185.46.13 port=5432 dbname=sistema user=postgres password=senha');
  EXCEPTION
      WHEN others THEN
          RAISE NOTICE '% (%)', SQLERRM, 'nome_cliente';
  END;                           

  -----------------------------------------------------------------------
  -- CARREGAMENTO EMPRESAS
  -----------------------------------------------------------------------
  delete from empresas;
  for x in (SELECT *
              FROM dblink('nome_cliente', 
                          'SELECT nnumeroempre, 
                                  cast(convert_to(crazaoempre, ''UTF8'') as varchar),
                                  cast(convert_to(cnomeempre , ''UTF8'') as varchar)
                             FROM solempre') 
                          t(nnumeroempre BIGINT, 
                            crazaoempre  VARCHAR(100), 
                            cnomeempre   VARCHAR(100))
          ORDER BY t.cnomeempre)
  loop
    insert into empresas (id_empresa,
                          razao,
                          fantasia)
                  values (x.nnumeroempre,
                          x.crazaoempre,
                          x.cnomeempre);
  end loop;


  -----------------------------------------------------------------------
  -- CARREGAMENTO CLIENTES
  -----------------------------------------------------------------------
  delete from clientes;
  for x in (SELECT *
              FROM dblink('nome_cliente', 
                          'SELECT nnumeroclien, 
                                  cast(convert_to(cnomeclien,   ''UTF8'') as varchar),
                                  cast(convert_to(cnfantaclien, ''UTF8'') as varchar),
                                  ctipopeclien, 
                                  ccnpjclien, 
                                  ccpfclien 
                             FROM solclien') 
                          t(nnumeroclien BIGINT, 
                            cnomeclien   VARCHAR(100), 
                            cnfantaclien VARCHAR(100), 
                            ctipopeclien CHAR(1), 
                            ccnpjclien   VARCHAR(20), 
                            ccpfclien    VARCHAR(20))
          ORDER BY t.cnomeclien)
  loop
    insert into clientes (id_cliente,
                          razao,
                          fantasia,
                          tipo_pessoa,
                          cnpj,
                          cpf)
                  values (x.nnumeroclien,
                          x.cnomeclien,
                          x.cnfantaclien,
                          x.ctipopeclien,
                          x.ccnpjclien,
                          x.ccpfclien);
  end loop;


  -----------------------------------------------------------------------
  -- CARREGAMENTO TIPO DE PEDIDO
  -----------------------------------------------------------------------    
  delete from tipo_pedido_venda;
  for x in (SELECT *
              FROM dblink('nome_cliente', 
                          'SELECT nnumerotpped, 
                                  cast(convert_to(cnometpped, ''UTF8'') as varchar),
                                  cmovesttpped, 
                                  cmovfintpped, 
                                  ctpvendtpped 
                             FROM soltpped') 
                          t(nnumerotpped BIGINT, 
                            cnometpped   VARCHAR(100), 
                            cmovesttpped CHAR(1), 
                            cmovfintpped CHAR(1), 
                            ctpvendtpped CHAR(1))
          ORDER BY t.cnometpped)
  loop
    insert into tipo_pedido_venda (id_tipo_pedido_venda,
                                   descricao,
                                   gera_estoque,
                                   gera_financeiro,
                                   venda)
                           values (x.nnumerotpped,
                                   x.cnometpped,
                                   x.cmovesttpped,
                                   x.cmovfintpped,
                                   x.ctpvendtpped);
  end loop;  

  -----------------------------------------------------------------------
  -- CARREGAMENTO FATURAMENTO
  -----------------------------------------------------------------------  
  delete from faturamento;
  for x in (SELECT *
              FROM dblink('nome_cliente', 
                          'SELECT a.nnumeroempre, 
                                  a.nnumerosaida, 
                                  a.nnumeroclien,
                                  (select b.nnumerotpped 
                                     from fatabert b
                                    where b.nnumerogrupo = a.nnumerogrupo
                                      and b.nnumeroempre = a.nnumeroempre
                                      and b.nnumeroabert = a.nnumeroabert) as nnumerotpped,
                                  a.demi_b09,
                                  a.nnf_b08,
                                  cast(convert_to(a.nome_cidade_destinatario, ''UTF8'') as varchar),
                                  a.uf_e12,
                                  cast(convert_to(a.nome_pais_destinatario, ''UTF8'') as varchar),
                                  a.vbc_w03,
                                  a.vicms_w04,
                                  a.vbcst_w05,
                                  a.vst_w06,
                                  a.vipi_w12,
                                  a.vpis_w13,
                                  a.vcofins_w14,
                                  a.voutro_w15,
                                  a.vprod_w07,
                                  a.vfrete_w08,
                                  a.vseg_w09,
                                  a.vdesc_w10,
                                  a.vnf_w16
                             FROM livnfe a
                            WHERE to_char(a.demi_b09,''YYYY'') >= ''2016''
                              AND a.dcancelanfe IS NULL') 
                          t(nnumeroempre BIGINT, 
                            nnumerosaida BIGINT,
                            nnumeroclien BIGINT,
                            nnumerotpped BIGINT,
                            demi_b09     DATE,
                            nnf_b08      BIGINT,
                            nome_cidade_destinatario VARCHAR(100),
                            uf_e12       VARCHAR(2),
                            nome_pais_destinatario CHAR(20),
                            vbc_w03      NUMERIC,
                            vicms_w04    NUMERIC,
                            vbcst_w05    NUMERIC,
                            vst_w06      NUMERIC,
                            vipi_w12     NUMERIC,
                            vpis_w13     NUMERIC,
                            vcofins_w14  NUMERIC,
                            voutro_w15   NUMERIC,
                            vprod_w07    NUMERIC,
                            vfrete_w08   NUMERIC,
                            vseg_w09     NUMERIC,
                            vdesc_w10    NUMERIC,
                            vnf_w16      NUMERIC))
  loop
    insert into faturamento (id_empresa,
                             id_faturamento,
                             id_cliente,
                             id_tipo_pedido_venda,
                             demi_b09,
                             nnf_b08,
                             nome_cidade_destinatario,
                             uf_e12,
                             nome_pais_destinatario,
                             vbc_w03,
                             vicms_w04,
                             vbcst_w05,
                             vst_w06,
                             vipi_w12,
                             vpis_w13,
                             vcofins_w14,
                             voutro_w15,
                             vprod_w07,
                             vfrete_w08,
                             vseg_w09,
                             vdesc_w10,
                             vnf_w16)
                     values (x.nnumeroempre,
                             x.nnumerosaida,
                             x.nnumeroclien,
                             x.nnumerotpped,
                             x.demi_b09,
                             x.nnf_b08,
                             x.nome_cidade_destinatario,
                             x.uf_e12,
                             x.nome_pais_destinatario,
                             x.vbc_w03,
                             x.vicms_w04,
                             x.vbcst_w05,
                             x.vst_w06,
                             x.vipi_w12,
                             x.vpis_w13,
                             x.vcofins_w14,
                             x.voutro_w15,
                             x.vprod_w07,
                             x.vfrete_w08,
                             x.vseg_w09,
                             x.vdesc_w10,
                             x.vnf_w16);
  end loop;

  return;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

	     