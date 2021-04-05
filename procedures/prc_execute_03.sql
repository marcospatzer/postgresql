CREATE OR REPLACE FUNCTION public.prc_execute_03 (
  p_grupo bigint,
  p_datain date,
  p_datafi date,
  tipo_data integer,
  p_espera char = 'S'::bpchar,
  p_producao char = 'S'::bpchar,
  p_produzir char = 'S'::bpchar,
  p_somar_programada char = 'S'::bpchar
)
RETURNS void AS
$body$
DECLARE

field                                 record;
field_update                          record;
itens                                 record;
r_1                                   record;
itens_extra                           record;
x                                     record;
itens_no_pcp                          record;   
v_auxiliar_setor                      integer;
v_contador_setor                      integer;
v_field                               text;
v_sql                                 text;
v_sql_update_espera                   text;
v_sql_update_a_produzir               text;
v_sql_update_produzindo               text;
v_seq                                 BIGINT;   
v_finalizado                          numeric;
v_qtde_setor_pai                      numeric;
v_virgula                             char(1);
v_qtde_pedido_filho_espera            numeric;
v_qtde_produzido                      numeric;
v_qtde_pedido_filho_produzir          numeric;   
v_pedido_associado                    varchar;
v_qtde_produzir                       numeric;
v_producao                            numeric;
v_pcpip                               indpcpip.nnumeropcpip%type;
v_producao_atual                      VARCHAR(500);
v_qtde_espera                         numeric;
v_qtde_produzindo                     numeric;
v_producao_item                       numeric;
v_pcpip_novo                          char;

BEGIN

   DROP TABLE IF EXISTS tb_analise_entrega_producao;
   v_auxiliar_setor := 0;
   v_field := '';
   for field in (  select b.cdescrisetin
                     from indsexgr a, indsetin b
                    where a.nnumerogruin = p_grupo
                      and b.nnumerosetin = a.nnumerosetin
                      AND a.ctpsetosexgr = 'P'
                 order by a.nsequenstxgr)
   loop
      v_auxiliar_setor := v_auxiliar_setor + 1;
      
      select count(*)
        into v_contador_setor
        from indsexgr a, indsetin b
       where a.nnumerogruin = p_grupo
         and a.ctpsetosexgr = 'P'
         and b.nnumerosetin = a.nnumerosetin; 
            
      IF p_espera = 'S' THEN
         v_field := v_field ||',' || prc_prepara_field(LOWER(field.cdescrisetin)) || '_espera NUMERIC DEFAULT 0';
      END IF;
      IF p_producao = 'S' THEN      
         v_field := v_field ||',' || prc_prepara_field(LOWER(field.cdescrisetin)) || '_produzindo NUMERIC DEFAULT 0';
      END IF;
      IF p_produzir = 'S' THEN            
         v_field := v_field ||',' || prc_prepara_field(LOWER(field.cdescrisetin)) || '_produzir NUMERIC DEFAULT 0'; 
      END IF;
   end loop;


  v_sql :=' create TEMPORARY table IF NOT EXISTS tb_analise_entrega_producao(
          id BIGSERIAL,  
          participa        CHAR(1),
          nnumeropcpip     BIGINT,
          nnumeropedid     BIGINT,
          nnumeroitped     BIGINT,
          codigo_pedido    BIGINT,
          data_pedido      DATE,
          data_entrega     DATE,
          data_pcp         DATE,
          data_liberacao   DATE,
          situacao         VARCHAR(40),
          situacao_item    VARCHAR(40),          
          cliente          VARCHAR(120),
          cliente_fantasia VARCHAR(120),
          cidade           VARCHAR(60),
          grupo            VARCHAR(60),  
          grife            VARCHAR(60),          
          referencia       VARCHAR(30),
          produto          VARCHAR(120),
          vlr_unitario     NUMERIC,
          vlr_total        NUMERIC,
          qtde_pedido      NUMERIC,
          qtde_entregue    NUMERIC,
          vlr_faturar      NUMERIC,          
          percentual_vinculado NUMERIC,
          saldo_entregar   NUMERIC,
          semana_entrega   VARCHAR(30),
          representante    VARCHAR(120),
          representante_comissao VARCHAR(200),         
          oc_cliente       VARCHAR(120),
          op               VARCHAR(120),
          finalizado       NUMERIC,
          producao_atual   VARCHAR(500),
          data_retorno_atual VARCHAR(500),
          a_programar      NUMERIC,
          producao         NUMERIC 
          %s
    );';
  v_sql := format(v_sql, v_field);  
  
  EXECUTE(v_sql);
  
  CREATE INDEX pk ON tb_analise_entrega_producao
    USING btree (id); 
      
  CREATE INDEX nnumeropcpip_idx ON tb_analise_entrega_producao
    USING btree (nnumeropcpip);     
    
  CREATE INDEX nnumeropedid_idx ON tb_analise_entrega_producao
    USING btree (nnumeropedid);
    
  CREATE INDEX nnumeroitped_idx ON tb_analise_entrega_producao
    USING btree (nnumeroitped);

  delete from tb_analise_entrega_producao;

  -- INICIO LEITURA DOS ITENS DOS PEDIDOS
  for itens in (SELECT campos                       
                  from tabelas
                 where condicoes
              ORDER BY aa.nnumeropedid)
  LOOP--/LOOP ITENS DOS PEDIDOS/
      v_seq := nextval('tb_analise_entrega_producao_id_seq');
      INSERT INTO tb_analise_entrega_producao
      (
        id,
        participa,
        nnumeroitped,
        nnumeropedid,
        codigo_pedido,
        data_pedido,
        data_entrega,
        data_pcp,
        data_liberacao,
        situacao,
        situacao_item,
        cliente,
        cliente_fantasia,
        cidade,
        grupo,
        grife,
        referencia,
        produto,
        vlr_unitario,
        vlr_total,
        qtde_pedido,
        qtde_entregue,
        saldo_entregar,
        percentual_vinculado,
        semana_entrega,
        representante,
        representante_comissao,
        oc_cliente,
        op,
        producao_atual,
        data_retorno_atual,
        a_programar       
      ) 
      VALUES (
        v_seq,
        'S',
        itens.nnumeroitped,
        itens.nnumeropedid,
        itens.ncodigopedid,
        itens.ddatapedid,
        itens.ddataentrega,
        itens.ddtlimpedid,
        itens.dliberapedid,
        itens.situacao,
        itens.situacao_item,
        itens.cliente,
        itens.cliente_fantasia,
        itens.cidade,
        itens.grupo,
        itens.grife,        
        itens.referencia,
        itens.cnomeprodu,
        itens.vlr_unitario,
        itens.valor_total,
        itens.qtde_pedido,
        itens.qtde_entregue,
        itens.qtde_entregar,
        itens.percentual_vinculado,        
        itens.semana_entrega,
        itens.cnomerepre,
        itens.representantes_comissao,        
        itens.oc_cliente,
        itens.ficha,
        NULL,
        itens.data_retorno_atual,
        itens.saldo_a_programar        
      );     

      v_pcpip := 0;
      v_pcpip_novo := 'S';
      v_producao_atual := '';      

      FOR field_update in (select campos
                             from tabelas
                            where condicoes
                         order by a.nsequenstxgr)
      LOOP--/LOOP SETORES DO ITEM DO PEDIDO/      
        IF v_pcpip <> field_update.nnumeropcpip THEN
           v_pcpip_novo := 'S';
        ELSE
           v_pcpip_novo := 'N';
        END IF;
        v_pcpip := field_update.nnumeropcpip;

        IF v_pcpip_novo = 'S' THEN
           UPDATE tb_analise_entrega_producao      
              SET nnumeropcpip = field_update.nnumeropcpip
            WHERE nnumeroitped = itens.nnumeroitped
              AND id = v_seq
              AND nnumeropcpip IS NULL;
        END IF;

        IF field_update.cfinalipcpst = 'N' THEN
            IF p_espera = 'S' THEN                  
               v_qtde_espera := prc_retorna_espera_setor_industrial(itens.nnumeroitped,field_update.nnumerosetin, 0,p_grupo);                          
               if coalesce(v_qtde_espera,0) > 0 then
                  v_sql_update_espera := '  UPDATE tb_analise_entrega_producao      
                                               SET %s = %s
                                             WHERE nnumeroitped = %s;';

                  v_sql_update_espera := format(v_sql_update_espera, (SELECT column_name 
                                                                        FROM information_schema.columns 
                                                                       WHERE table_name = 'tb_analise_entrega_producao'
                                                                         AND column_name = LOWER(field_update.cdescrisetin)||'_espera'), 
                                                                      v_qtde_espera,
                                                                      itens.nnumeroitped);   
                  EXECUTE(v_sql_update_espera);

                  if coalesce(v_qtde_espera,0) > 0 then
                     if v_producao_atual = '' then 
                         v_producao_atual := v_producao_atual || ' ESPERA ' || (field_update.cdescrisetin);               
                     else
                         v_producao_atual := v_producao_atual || ' - ' || ' ESPERA ' || (field_update.cdescrisetin);                             
                     end if;
                  end if; 
               end if; 
            END IF;                                                              
 
            IF p_producao = 'S' AND field_update.dentradpcpst is not null THEN                                                                                                                          
               v_qtde_produzindo := prc_retorna_saldo_produzindo_setor_industrial(itens.nnumeroitped, field_update.nnumerosetin);    
               if coalesce(v_qtde_produzindo,0) > 0 then                          
                  v_sql_update_produzindo := '  UPDATE tb_analise_entrega_producao      
                                                   SET %s = %s
                                                 WHERE nnumeroitped = %s;';
                                                  
                  v_sql_update_produzindo := format(v_sql_update_produzindo, (SELECT column_name  
                                                                                FROM information_schema.columns 
                                                                               WHERE table_name = 'tb_analise_entrega_producao'
                                                                                 AND column_name = LOWER(field_update.cdescrisetin)||'_produzindo'), 
                                                                              v_qtde_produzindo,
                                                                              itens.nnumeroitped); 
                                                                          
                  EXECUTE(v_sql_update_produzindo);

                  if coalesce(v_qtde_produzindo,0) > 0 then
                     if v_producao_atual = '' then 
                        v_producao_atual := v_producao_atual || ' PRODUZINDO ' || (field_update.cdescrisetin); 
                     else
                        v_producao_atual := v_producao_atual  || ' - ' ||  ' PRODUZINDO ' || (field_update.cdescrisetin);                          
                     end if;              
                  end if;   
               end if;               
            END IF;                       

            IF p_produzir = 'S' THEN           
               v_sql_update_a_produzir := '  UPDATE tb_analise_entrega_producao      
                                                SET %s = %s
                                              WHERE nnumeroitped = %s;';
               v_sql_update_a_produzir := format(v_sql_update_a_produzir,  
                                                 (SELECT column_name 
                                                   FROM information_schema.columns 
                                                  WHERE table_name = 'tb_analise_entrega_producao'
                                                    AND column_name = LOWER(field_update.cdescrisetin)||'_produzir'),
                                                 prc_retorna_saldo_setor_industrial(itens.nnumeroitped, field_update.nnumerosetin),                                                  
                                                 itens.nnumeroitped);
               EXECUTE(v_sql_update_a_produzir);
            END IF;
        END IF;

        IF v_pcpip_novo = 'S' THEN        
           SELECT prc_retorna_qtde_atual_pcp(field_update.nnumeropcpip)
             INTO v_finalizado
             FROM INDPCPIP B 
            WHERE B.NNUMEROITPED =  itens.nnumeroitped
              AND not exists (select i.nnumeropcpst 
                                from indpcpst i, indsexgr j
                               where i.nnumeropcpip = B.nnumeropcpip 
                               and i.nnumerogruin = j.nnumerogruin
                               and i.nnumerosetin = j.nnumerosetin
                               and i.cpassagpcpst = 'S' 
                               and i.cfinalipcpst = 'N'
                               and j.ctpsetosexgr = 'P');

           UPDATE tb_analise_entrega_producao      
              SET finalizado   = v_finalizado
            WHERE id = v_seq;

           v_producao_item := 0;
           FOR itens_no_pcp IN (SELECT ta.nnumeropcpip, ta.nnumeroitped
                                  FROM indpcpip ta
                                 WHERE ta.nnumeroitped = itens.nnumeroitped)
           LOOP                      
              v_producao_item :=  coalesce(v_producao_item,0) + coalesce(prc_retorna_qtde_producao_pcp(itens_no_pcp.nnumeropcpip,itens_no_pcp.nnumeroitped),0);
           END LOOP;
        END IF;

      END LOOP;--/LOOP SETORES DO ITEM DO PEDIDO/


      UPDATE tb_analise_entrega_producao      
         SET producao   = v_producao_item 
       WHERE id = v_seq;    

      UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
         SET producao_atual =  v_producao_atual  
       WHERE id = v_seq; 
  
  END LOOP;--/LOOP ITENS DOS PEDIDOS/



  for itens_extra in (SELECT campos                                               
                        from tabelas
                       where condicoes
                    ORDER BY aa.nnumeropedid)
   LOOP
      v_seq := nextval('tb_analise_entrega_producao_id_seq');
      INSERT INTO tb_analise_entrega_producao
      (
        id,
        participa,
        nnumeroitped,
        nnumeropedid,
        codigo_pedido,
        data_pedido,
        data_entrega,
        data_pcp,
        data_liberacao,
        situacao,
        cliente,
        cliente_fantasia,
        cidade,
        grupo,
        referencia,
        produto,
        vlr_unitario,
        vlr_total,
        qtde_pedido,
        qtde_entregue,
        saldo_entregar,
        semana_entrega,
        representante,
        representante_comissao,
        oc_cliente,
        op,
        producao_atual,
        a_programar        
      ) 
      VALUES (
        v_seq,
        'N',
        itens_extra.nnumeroitped,
        itens_extra.nnumeropedid,
        itens_extra.ncodigopedid,
        itens_extra.ddatapedid,
        itens_extra.ddataentrega,
        itens_extra.ddtlimpedid,
        itens_extra.dliberapedid,
        itens_extra.situacao,
        itens_extra.cliente,
        itens_extra.cliente_fantasia,
        itens_extra.cidade,
        itens_extra.grupo,
        itens_extra.referencia,
        itens_extra.cnomeprodu,
        itens_extra.vlr_unitario,
        itens_extra.valor_total,
        itens_extra.qtde_pedido,
        itens_extra.qtde_entregue,
        itens_extra.qtde_entregar,
        itens_extra.semana_entrega,
        itens_extra.cnomerepre,
        itens_extra.representantes_comissao,        
        itens_extra.oc_cliente,
        itens_extra.ficha,
        NULL,--itens_extra.producao_atual,
        itens_extra.saldo_a_programar        
      ); 
      
      FOR field_update in (select campos
                             from tabelas
                            where condicoes
                         order by a.nsequenstxgr)
      LOOP      
        UPDATE tb_analise_entrega_producao      
           SET nnumeropcpip = field_update.nnumeropcpip
         WHERE nnumeroitped = itens_extra.nnumeroitped
           AND id = v_seq;
                            
        IF p_espera = 'S' THEN      
           v_sql_update_espera := '  UPDATE tb_analise_entrega_producao      
                                        SET %s = %s
                                      WHERE nnumeroitped = %s;';
                                      
           v_sql_update_espera := format(v_sql_update_espera, (SELECT column_name 
                                                                 FROM information_schema.columns 
                                                                WHERE table_name = 'tb_analise_entrega_producao'
                                                                  AND column_name = LOWER(field_update.cdescrisetin)||'_espera'), 
                                                               prc_retorna_espera_setor_industrial(itens_extra.nnumeroitped,field_update.nnumerosetin, 0,p_grupo),
                                                               itens_extra.nnumeroitped);   
           EXECUTE(v_sql_update_espera);
        END IF;                                                              

        IF p_producao = 'S' THEN                                                                                                                          
           v_sql_update_produzindo := '  UPDATE tb_analise_entrega_producao      
                                            SET %s = %s
                                          WHERE nnumeroitped = %s;';
                                          
           v_sql_update_produzindo := format(v_sql_update_produzindo, (SELECT column_name  
                                                                         FROM information_schema.columns 
                                                                        WHERE table_name = 'tb_analise_entrega_producao'
                                                                          AND column_name = LOWER(field_update.cdescrisetin)||'_produzindo'), 
                                                               prc_retorna_saldo_produzindo_setor_industrial(itens_extra.nnumeroitped, field_update.nnumerosetin),
                                                               itens_extra.nnumeroitped);    
                                                                  
           EXECUTE(v_sql_update_produzindo);                                        
        END IF;                       
        IF p_produzir = 'S' THEN
           v_sql_update_a_produzir := '  UPDATE tb_analise_entrega_producao      
                                            SET %s = %s
                                         WHERE nnumeroitped = %s;';
                                                    
           v_sql_update_a_produzir := format(v_sql_update_a_produzir,  
                                             (SELECT column_name 
                                               FROM information_schema.columns 
                                              WHERE table_name = 'tb_analise_entrega_producao'
                                                AND column_name = LOWER(field_update.cdescrisetin)||'_produzir'),
                                             prc_retorna_saldo_setor_industrial(itens.nnumeroitped, field_update.nnumerosetin),                                                  
                                             itens_extra.nnumeroitped
                                             );  

           EXECUTE(v_sql_update_a_produzir);   
        END IF;
        SELECT prc_retorna_qtde_atual_pcp(field_update.nnumeropcpip)
          INTO v_finalizado
          FROM INDPCPIP B
         WHERE B.NNUMEROITPED =  itens_extra.nnumeroitped
           AND not exists (select i.nnumeropcpst 
                           from indpcpst i, indsexgr j-- sol2462
                          where i.nnumeropcpip = B.nnumeropcpip 
                            and i.nnumerogruin = j.nnumerogruin
                            and i.nnumerosetin = j.nnumerosetin                          
                            and i.cpassagpcpst = 'S' 
                            and i.cfinalipcpst = 'N'
                            and j.ctpsetosexgr = 'P' );
                            
        UPDATE tb_analise_entrega_producao      
           SET finalizado   = v_finalizado
         WHERE id = v_seq;    

      END LOOP;
   END LOOP;       

   FOR r_1 in (SELECT * 
                 FROM INDPCXIT TA ,TB_ANALISE_ENTREGA_PRODUCAO lc
                WHERE TA.NNUMITPEDVEN = lc.NNUMEROITPED
                ORDER BY lc.data_entrega)
   LOOP
      v_qtde_pedido_filho_espera     := r_1.qtde_pedido; 
      v_qtde_pedido_filho_produzir   := r_1.qtde_pedido;

      v_qtde_produzido               := 0;
      v_pedido_associado             := (select op from TB_ANALISE_ENTREGA_PRODUCAO where nnumeroitped = r_1.nnumeroitped);

      UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
         SET qtde_pedido    =  COALESCE(qtde_pedido,0) - COALESCE(r_1.qtde_pedido,0),
             qtde_entregue  =  COALESCE(qtde_entregue,0) - COALESCE(r_1.qtde_entregue,0),
             saldo_entregar =  COALESCE(saldo_entregar,0) - COALESCE(r_1.saldo_entregar,0),
             vlr_total      =  COALESCE(qtde_pedido,0) * COALESCE(r_1.vlr_unitario,0)
       WHERE NNUMEROITPED = r_1.nnumeroitped
         AND NNUMEROPCPIP = r_1.nnumeropcpip;
         
      UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
         SET a_programar = 0,
             op =  v_pedido_associado             
       WHERE NNUMEROITPED = r_1.NNUMITPEDVEN;
       
      for field in (  select prc_prepara_field(b.cdescrisetin) as cdescrisetin 
                        from indsexgr a, indsetin b
                       where a.nnumerogruin = p_grupo
                         and b.nnumerosetin = a.nnumerosetin
                         and a.ctpsetosexgr = 'P' -- 2462
                    order by a.nsequenstxgr desc)
      loop
         v_field := ''; 
               

         IF p_produzir = 'S' THEN  
                                
            v_field :=  LOWER(field.cdescrisetin) || '_produzir'; 
            v_sql :=  'SELECT %s
                         FROM TB_ANALISE_ENTREGA_PRODUCAO A
                        WHERE NNUMEROITPED = %s
                          AND NNUMEROPCPIP = %s';
                         
            v_sql := format(v_sql,   v_field, r_1.nnumeroitped, r_1.nnumeropcpip ); 
            EXECUTE(v_sql) INTO v_qtde_setor_pai ;                            
                      
            IF COALESCE(v_qtde_setor_pai,0) = 0 THEN           
               v_sql :=  'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                             SET %s = 0          
                           WHERE NNUMEROITPED = %s';
               v_sql := format(v_sql,   v_field, r_1.nnumitpedven); 
               EXECUTE(v_sql);      
                                                   
            ELSIF COALESCE(v_qtde_setor_pai,0) > (COALESCE(v_qtde_pedido_filho_produzir,0) - COALESCE(v_qtde_produzido,0)) THEN                                         
               v_sql := 'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                            SET %s = COALESCE(%s,0)             
                          WHERE NNUMEROITPED = %s';
                                    
               v_sql := format(v_sql,   v_field, (COALESCE(v_qtde_pedido_filho_produzir,0) - COALESCE(v_qtde_produzido,0)),  r_1.nnumitpedven); 
               EXECUTE(v_sql);    
                            
               v_sql := 'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                            SET %s = COALESCE(%s,0) - COALESCE(%s,0)             
                          WHERE NNUMEROITPED = %s';       
                                    
               v_sql := format(v_sql,   v_field, v_field, (COALESCE(v_qtde_pedido_filho_produzir,0) - COALESCE(v_qtde_produzido,0)),  r_1.NNUMEROITPED); 
               EXECUTE(v_sql); 
                                    
            ELSE
               v_sql := 'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                            SET %s = COALESCE(%s,0)             
                          WHERE NNUMEROITPED = %s';
                                    
               v_sql := format(v_sql,   v_field, v_qtde_setor_pai, r_1.nnumitpedven); 
               EXECUTE(v_sql);                          
                            
               v_sql := 'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                            SET %s = 0            
                          WHERE NNUMEROITPED = %s';     
                                    
               v_sql := format(v_sql,   v_field, r_1.NNUMEROITPED); 
               EXECUTE(v_sql);   
                                     
            END IF;              
        END IF; 
        
        IF p_espera = 'S' THEN
           IF COALESCE(v_qtde_pedido_filho_espera,0) > 0 THEN                      
              v_field :=  LOWER(field.cdescrisetin) || '_espera';
              v_sql :=  'SELECT %s
                           FROM TB_ANALISE_ENTREGA_PRODUCAO A
                          WHERE NNUMEROITPED = %s
                            AND NNUMEROPCPIP = %s';
                      
              v_sql := format(v_sql,   v_field, r_1.nnumeroitped, r_1.nnumeropcpip ); 
              EXECUTE(v_sql) INTO v_qtde_setor_pai ;                            

              IF COALESCE(v_qtde_setor_pai,0) = 0 THEN           
                 v_sql :=  'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                               SET %s = 0          
                             WHERE NNUMEROITPED = %s';
                 v_sql := format(v_sql,   v_field, r_1.nnumitpedven); 
                 EXECUTE(v_sql);                  
                     
              ELSIF COALESCE(v_qtde_setor_pai,0) > COALESCE(v_qtde_pedido_filho_espera,0) THEN
                 v_sql := 'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                              SET %s = COALESCE(%s,0)             
                            WHERE NNUMEROITPED = %s';
                                 
                 v_sql := format(v_sql,   v_field, v_qtde_pedido_filho_espera,  r_1.nnumitpedven); 
                 EXECUTE(v_sql);    
                         
                 v_sql := 'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                              SET %s = COALESCE(%s,0) - COALESCE(%s,0)             
                            WHERE NNUMEROITPED = %s';       
                                 
                 v_sql := format(v_sql,   v_field, v_field, v_qtde_pedido_filho_espera,  r_1.NNUMEROITPED); 
                 EXECUTE(v_sql);
                 v_qtde_produzido := COALESCE(v_qtde_produzido,0) + COALESCE(v_qtde_pedido_filho_espera,0);
                 v_qtde_pedido_filho_espera := 0;                                                      
              ELSE
                 v_sql := 'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                              SET %s = COALESCE(%s,0)             
                            WHERE NNUMEROITPED = %s';
                                 
                 v_sql := format(v_sql,   v_field, v_qtde_setor_pai, r_1.nnumitpedven); 
                 EXECUTE(v_sql);                          
                         
                 v_sql := 'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                              SET %s = 0            
                            WHERE NNUMEROITPED = %s';     
                                 
                 v_sql := format(v_sql,   v_field, r_1.NNUMEROITPED); 
                 EXECUTE(v_sql);   
                 v_qtde_produzido := COALESCE(v_qtde_produzido,0) + COALESCE(v_qtde_setor_pai,0); 
                 v_qtde_pedido_filho_espera := COALESCE(v_qtde_pedido_filho_espera,0) - COALESCE(v_qtde_setor_pai,0);  
              END IF; 
                  
           END IF;
                    
        END IF;
        IF p_producao = 'S' THEN  
           IF COALESCE(v_qtde_pedido_filho_espera,0) > 0 THEN                    
              v_field :=  LOWER(field.cdescrisetin) || '_produzindo';
              v_sql :=  'SELECT %s
                           FROM TB_ANALISE_ENTREGA_PRODUCAO A
                          WHERE NNUMEROITPED = %s
                            AND NNUMEROPCPIP = %s';
                      
              v_sql := format(v_sql,   v_field, r_1.nnumeroitped, r_1.nnumeropcpip ); 
              EXECUTE(v_sql) INTO v_qtde_setor_pai ;                            

              IF COALESCE(v_qtde_setor_pai,0) = 0 THEN           
                 v_sql :=  'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                               SET %s = 0          
                             WHERE NNUMEROITPED = %s';
                 v_sql := format(v_sql,   v_field, r_1.nnumitpedven); 
                 EXECUTE(v_sql);                  
                     
              ELSIF COALESCE(v_qtde_setor_pai,0) > COALESCE(v_qtde_pedido_filho_espera,0) THEN
                 v_sql := 'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                              SET %s = COALESCE(%s,0)             
                            WHERE NNUMEROITPED = %s';
                                 
                 v_sql := format(v_sql,   v_field, v_qtde_pedido_filho_espera,  r_1.nnumitpedven); 
                 EXECUTE(v_sql);    
                         
                 v_sql := 'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                              SET %s = COALESCE(%s,0) - COALESCE(%s,0)             
                            WHERE NNUMEROITPED = %s';       
                                 
                 v_sql := format(v_sql,   v_field, v_field, v_qtde_pedido_filho_espera,  r_1.NNUMEROITPED); 
                 EXECUTE(v_sql); 
                 v_qtde_produzido := COALESCE(v_qtde_produzido,0) + COALESCE(v_qtde_pedido_filho_espera,0);
                 v_qtde_pedido_filho_espera := 0;                                  
              ELSE
                 v_sql := 'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                              SET %s = COALESCE(%s,0)             
                            WHERE NNUMEROITPED = %s';
                                 
                 v_sql := format(v_sql,   v_field, v_qtde_setor_pai, r_1.nnumitpedven); 
                 EXECUTE(v_sql);                          
                         
                 v_sql := 'UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
                              SET %s = 0            
                            WHERE NNUMEROITPED = %s';     
                                 
                 v_sql := format(v_sql,   v_field, r_1.NNUMEROITPED); 
                 EXECUTE(v_sql);   
                 v_qtde_produzido := COALESCE(v_qtde_produzido,0) + COALESCE(v_qtde_setor_pai,0);
                 v_qtde_pedido_filho_espera := COALESCE(v_qtde_pedido_filho_espera,0) - COALESCE(v_qtde_setor_pai,0);                         
              END IF;                 
           END IF;  
        END IF;
      END LOOP;    
   END LOOP;   

  DELETE FROM TB_ANALISE_ENTREGA_PRODUCAO WHERE participa = 'N';     
  
  UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
     SET vlr_total      =  COALESCE(qtde_pedido,0) * COALESCE(vlr_unitario,0);
             
  UPDATE TB_ANALISE_ENTREGA_PRODUCAO 
     SET vlr_faturar    =  ((COALESCE(saldo_entregar,0) * COALESCE(vlr_unitario,0)) * (100 - COALESCE(percentual_vinculado,0)) /100);
        
  IF COALESCE(p_somar_programada, 'S') = 'S' THEN 
     v_sql := 'UPDATE TB_ANALISE_ENTREGA_PRODUCAO SET';  
     FOR x in (SELECT prc_prepara_field(LOWER(b.cdescrisetin)) || '_produzir' as produzir
                 FROM indsexgr a, indsetin b
                WHERE a.nnumerogruin = p_grupo
                  AND b.nnumerosetin = a.nnumerosetin
                  AND a.ctpsetosexgr = 'P'
             ORDER BY a.nsequenstxgr)
     LOOP   
     v_field := x.produzir;               
     v_sql :=  v_sql || ' %s =  COALESCE(%s,0) + COALESCE(a_programar,0),';       
     v_sql := format(v_sql, v_field, v_field);
     
     END LOOP;
     
     v_sql := (SELECT SUBSTR(v_sql, 1, length(v_sql) -1));                
     
     EXECUTE(v_sql);     
  END IF;
  
  RETURN;
   
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;