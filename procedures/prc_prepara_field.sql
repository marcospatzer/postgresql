CREATE OR REPLACE FUNCTION public.prc_prepara_field (
  p_campo varchar
)
RETURNS varchar AS
$body$
DECLARE
BEGIN
   RETURN prc_retira_caracter_especial_field(REPLACE(prc_retira_caracter_acentuacao(replace(replace(p_campo,' ','_'), '-','_')), '.', ''));
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
