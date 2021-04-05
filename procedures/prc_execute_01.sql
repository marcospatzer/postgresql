CREATE OR REPLACE FUNCTION public.prc_execute_01 (
  p_itped bigint,
  p_grupo bigint,
  p_espera char,
  p_producao char,
  p_produzir char
)
RETURNS varchar AS
$body$
DECLARE
  x             RECORD;
  v_setores     VARCHAR;
  v_sql         TEXT;
  v_setor_loop  NUMERIC;
  v_contador    integer;
  v_producao_atual varchar(500);
BEGIN
   v_setores := '';
   v_producao_atual := '';
   SELECT producao_atual
     INTO v_producao_atual
     FROM TB_ANALISE_ENTREGA_PRODUCAO A
    WHERE A.nnumeroitped = p_itped;
    
   IF COALESCE(v_producao_atual,'') <> '' THEN
      v_setores := ' - ';
   END IF;
   
   FOR x in (SELECT prc_prepara_field(LOWER(b.cdescrisetin)) || '_espera' as espera,
                    prc_prepara_field(LOWER(b.cdescrisetin)) || '_produzindo' as produzindo,
                    prc_prepara_field(b.cdescrisetin) as cdescrisetin
               FROM indsexgr a, indsetin b
              WHERE a.nnumerogruin = p_grupo
                AND b.nnumerosetin = a.nnumerosetin
                AND a.ctpsetosexgr = 'P'
              ORDER BY a.nsequenstxgr)
   LOOP
    IF p_espera = 'S' THEN   
       v_sql := ' SELECT %s
                    FROM TB_ANALISE_ENTREGA_PRODUCAO a
                   WHERE a.nnumeroitped = %s';        
       
       v_sql := format(v_sql, x.espera, COALESCE(p_itped,0));   
       EXECUTE(v_sql) INTO v_setor_loop;     
       IF COALESCE(v_setor_loop,0) <> 0 THEN
          v_setores := v_setores || 'ESPERA '|| x.cdescrisetin || ' - '; 
       END IF;
    END IF;
    
    IF p_produzir = 'S' THEN       
       v_sql := ' SELECT %s
                    FROM TB_ANALISE_ENTREGA_PRODUCAO a
                   WHERE a.nnumeroitped = %s
                     AND NOT EXISTS(SELECT B.NNUMEROITPED
                                      FROM INDPCPIP B
                                     WHERE B.NNUMEROITPED = A.NNUMEROITPED)';        
       
       v_sql := format(v_sql, x.produzindo, COALESCE(p_itped,0));   
       EXECUTE(v_sql) INTO v_setor_loop;  
       
       IF COALESCE(v_setor_loop,0) <> 0 THEN
          v_setores := v_setores ||  'PRODUZINDO '|| x.cdescrisetin || ' - '; 
       END IF;       
    END IF; 
    
    
    END LOOP;
   RETURN COALESCE(v_setores);
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
