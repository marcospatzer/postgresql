/* 
select prc_extrato_produto(:p_almox, :p_produto, cast(:p_data_in as date), cast(:p_data_fi as date), :p_unidade, :p_sld_ant);

  select a.*
    from tb_extrato_produto a
order by sequencia;
*/

CREATE OR REPLACE FUNCTION public.prc_extrato_produto (
  p_almox bigint,
  p_produto bigint,
  p_data_in date,
  p_data_fi date,
  p_unidade bigint,
  p_sld_ant numeric,
  p_2un char,
  p_sld_ant_2un numeric
)
RETURNS void AS
$body$
DECLARE

x         	 record;

v_sequencia  bigint;
v_saldo      numeric;
v_saldo_2un  numeric;

BEGIN

  create TEMPORARY table IF NOT EXISTS tb_extrato_produto(
         sequencia    BIGINT,
         nnumerogrupo BIGINT,
         nnumeroempre BIGINT,
         nnumeromovim BIGINT,
         nnumeroitmov BIGINT,
         nnumeroprodu BIGINT,
         nnumerograde BIGINT,
         ccodigomovim VARCHAR(20),
         cdescrimovim VARCHAR(60),
         entsai       CHAR,
         cdescritpmov VARCHAR(60),
         ddatamovim   DATE,
         csiglaunida  VARCHAR(6),
         entrada      NUMERIC,
         saida        NUMERIC, 
         saldo        NUMERIC,
         entrada_2un  NUMERIC,
         saida_2un    NUMERIC,
         saldo_2un    NUMERIC,
         sem_lote     CHAR
    );
  delete from tb_extrato_produto;

  v_sequencia := 0;
  v_saldo     := p_sld_ant;
  v_saldo_2un := p_sld_ant_2un;
  for x in (select i.nnumerogrupo,
                   i.nnumeroempre,
                   i.nnumeromovim,
                   i.nnumeroitmov,
                   i.nnumeroprodu,
                   p.nnumerograde,
                   m.ccodigomovim,
                   m.cdescrimovim,
                   t.centsaitpmov as entsai,
                   t.cdescritpmov,
                   date(m.ddatamovim) as data,
                   CASE WHEN t.centsaitpmov = 'S' THEN
                          PRC_ESTCONVERTE_UNIDADE(i.nnumeroprodu,i.nnumerounida,p_unidade,i.nquantiitmov) 
                        ELSE 
                          0 
                   END as saida,
                   CASE WHEN t.centsaitpmov = 'S' THEN
                          PRC_ESTCONVERTE_UNIDADE(i.nnumeroprodu,i.nnumerounida,p_unidade,i.nqtseguitmov) 
                        ELSE 
                          0 
                   END as saida_2un,

                   CASE WHEN t.centsaitpmov = 'E' THEN
                          PRC_ESTCONVERTE_UNIDADE(i.nnumeroprodu,i.nnumerounida,p_unidade,i.nquantiitmov) 
                        ELSE 
                          0 
                   END as entrada,
                   CASE WHEN t.centsaitpmov = 'E' THEN
                          PRC_ESTCONVERTE_UNIDADE(i.nnumeroprodu,i.nnumerounida,p_unidade,i.nqtseguitmov) 
                        ELSE 
                          0 
                   END as entrada_2un,
                   prc_itmov_sem_lote(i.nnumerogrupo, i.nnumeroempre, i.nnumeromovim, i.nnumeroitmov) as sem_lote,
                   u.csiglaunida,
                   i.nnumerounida
                from estitmov i, estmovim m, esttpmov t, solprodu p, solunida u
               where i.nnumeroprodu = p_produto
                 and m.nnumeromovim = i.nnumeromovim
                 and date(m.ddatamovim) >= p_data_in
                 and date(m.ddatamovim) <= p_data_fi
                 and m.nnumeroalmox = p_almox
                 and t.nnumerotpmov = m.nnumerotpmov
                 and p.nnumeroprodu = i.nnumeroprodu
                 and u.nnumerounida = p.nnumerounida
            order by date(m.ddatamovim), t.centsaitpmov, m.nnumeromovim)
  loop
    v_sequencia := v_sequencia + 1;
    v_saldo     := v_saldo + x.entrada - x.saida;
    v_saldo_2un := v_saldo_2un + x.entrada_2un - x.saida_2un;
    insert into tb_extrato_produto (sequencia,   
                                    nnumerogrupo,
                                    nnumeroempre,
                                    nnumeromovim,
                                    nnumeroitmov,
                                    nnumeroprodu,
                                    nnumerograde,
                                    ccodigomovim,
                                    cdescrimovim,
                                    entsai,      
                                    cdescritpmov,
                                    ddatamovim,  
                                    csiglaunida, 
                                    entrada,     
                                    saida,
                                    saldo,      
                                    entrada_2un, 
                                    saida_2un,   
                                    saldo_2un,
                                    sem_lote)
                            values (v_sequencia,
                                    x.nnumerogrupo,
                                    x.nnumeroempre,
                                    x.nnumeromovim,
                                    x.nnumeroitmov,
                                    x.nnumeroprodu,
                                    x.nnumerograde,
                                    x.ccodigomovim,
                                    x.cdescrimovim,
                                    x.entsai,      
                                    x.cdescritpmov,
                                    x.data,  
                                    x.csiglaunida, 
                                    x.entrada,     
                                    x.saida,
                                    v_saldo,       
                                    x.entrada_2un, 
                                    x.saida_2un,   
                                    v_saldo_2un,
                                    x.sem_lote);
  end loop;

  RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;





