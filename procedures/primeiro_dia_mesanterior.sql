CREATE OR REPLACE FUNCTION public.primeiro_dia_mesanterior (
)
RETURNS date AS
$body$
select
   cast(date_trunc('month', CURRENT_DATE) - '1 month'::interval as date)
$body$
LANGUAGE 'sql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
