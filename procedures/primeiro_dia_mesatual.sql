CREATE OR REPLACE FUNCTION public.primeiro_dia_mesatual (
)
RETURNS date AS
$body$
select
   cast(date_trunc('month', CURRENT_DATE) as date)
$body$
LANGUAGE 'sql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;