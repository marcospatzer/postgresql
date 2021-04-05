CREATE TRIGGER tri_empresa_base
  AFTER INSERT OR UPDATE 
  ON public.tb_empre
  
FOR EACH ROW 
  EXECUTE PROCEDURE public.prc_tri_empresa_base();



CREATE OR REPLACE FUNCTION public.prc_tri_empresa_base (
)
RETURNS trigger AS
$body$
DECLARE
	v_grubas_old	solempre.ngrubasempre%type;
	v_empbas_old	solempre.nempbasempre%type;
    
    v_proximo	    BIGINT;
    v_complemento	varchar;
    
    r_1				record;
    r_2				record;

BEGIN
	v_grubas_old := NULL;
	v_empbas_old := NULL;
	IF TG_OP = 'UPDATE' THEN
    	v_grubas_old := OLD.ngrubasempre;
    	v_empbas_old := OLD.nempbasempre;
    END IF;
    
    IF ((COALESCE(NEW.nempbasempre,0) <> 0) AND (COALESCE(v_empbas_old,0) <> COALESCE(NEW.nempbasempre,0))) THEN
        FOR r_1 IN (SELECT descricao, complemento
                      FROM v_parametros_replicar)
        LOOP
        	v_complemento := r_1.complemento;
        	
        	FOR r_2 IN (SELECT 'select nextval('||
                               substr(a.column_default,
                               "position"(a.column_default,chr(39)),
                               "position"(substr(a.column_default,"position"(a.column_default,chr(39))+1),chr(39))+1)||
                               ')' as sequence,
                               "position"(a.column_default, 'nextval') as existe,
                               a.column_name
                          FROM information_schema.columns a
                         WHERE a.table_schema = 'public'
                           AND a.table_name   = r_1.descricao)
            LOOP
            	IF r_2.existe > 0 THEN
                	v_proximo := NULL;
                	EXECUTE (r_2.sequence) into v_proximo;
                	v_complemento := v_complemento||', '||r_2.column_name||' = '||v_proximo;
                END IF;
            END LOOP;
            
            EXECUTE 'DELETE FROM '||r_1.descricao||
                    ' WHERE nnumerogrupo = '||NEW.nnumerogrupo||
                    '   AND nnumeroempre = '||NEW.nnumeroempre||';';
            
            EXECUTE 'CREATE TABLE '||r_1.descricao||'_temp'||
                    '    AS SELECT *'||
                    '         FROM '||r_1.descricao||
                    '        WHERE nnumerogrupo = '||NEW.ngrubasempre||
                    '          AND nnumeroempre = '||NEW.nempbasempre||';';
            
            EXECUTE 'UPDATE '||r_1.descricao||'_temp'||
                    '   SET nnumerogrupo = '||NEW.nnumerogrupo||','||
                    '       nnumeroempre = '||NEW.nnumeroempre||
                    v_complemento||';';
            
            EXECUTE 'INSERT INTO '||r_1.descricao||' '||
                    'SELECT * FROM '||r_1.descricao||'_temp'||';';
            
            EXECUTE 'DROP TABLE '||r_1.descricao||'_temp'||';';
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
