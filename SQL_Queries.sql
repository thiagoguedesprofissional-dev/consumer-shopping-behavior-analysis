select * from customer;
-- Q1. Qual é a receita total gerada por homens vs. mulheres?

select gender, SUM(purchase_amount) as total_receita
from customer
group by gender;
-- Q2. Quais clientes usaram desconto, mas ainda assim gastaram mais que a média?
SELECT 
    COUNT(CASE 
            WHEN discount_applied = 'Yes' 
            AND purchase_amount >= (SELECT AVG(purchase_amount) FROM customer) 
            THEN 1 
          END) * 100.0 / COUNT(*) AS pct_clientes_elite_desconto
FROM 
    customer;
select customer_id,purchase_amount
from customer
where discount_applied = 'Yes' and purchase_amount >= (select AVG(purchase_amount) from customer);
-- Outra query
select 
	gender,
	sum(purchase_amount) as total_gasto
from customer
where discount_applied = 'Yes' and purchase_amount >= (select AVG(purchase_amount) from customer)
group by gender;

SELECT 
    COUNT(*) AS total_base_clientes,
    SUM(CASE 
            WHEN discount_applied = 'Yes' AND purchase_amount >= (SELECT AVG(purchase_amount) FROM customer) 
            THEN 1 ELSE 0 
        END) AS total_clientes_elite,
    ROUND(
        SUM(CASE 
                WHEN discount_applied = 'Yes' AND purchase_amount >= (SELECT AVG(purchase_amount) FROM customer) 
                THEN 1.0 ELSE 0 
            END) * 100 / COUNT(*), 2
    ) AS porcentagem_representatividade
FROM 
    customer;
---Outra query
SELECT 
    gender, 
    purchase_amount
FROM customer
WHERE discount_applied = 'Yes' 
  AND purchase_amount >= (SELECT AVG(purchase_amount) FROM customer)
ORDER BY gender;

SELECT 
    gender,
    COUNT(*) AS qtd_clientes,
    SUM(purchase_amount) AS total_gasto,
    -- Porcentagem de quanto esse gênero representa no faturamento desse grupo "Elite"
    ROUND(SUM(purchase_amount) * 100.0 / SUM(SUM(purchase_amount)) OVER(), 2) AS pct_do_faturamento_elite
FROM 
    customer
WHERE 
    discount_applied = 'Yes' 
    AND purchase_amount >= (SELECT AVG(purchase_amount) FROM customer)
GROUP BY 
    gender;
-- Q3. Quais são os 5 produtos com a maior nota média de avaliação?
select
	item_purchased, 
	avg(review_rating) as media_nota
from customer
group by item_purchased
order by media_nota desc
limit 5;
-- Q4. Compare o valor médio de compra entre o envio Padrão (Standard) e Expresso (Express).
select shipping_type from customer;

select 
	shipping_type,
	round(avg(purchase_amount),2) as valor_médio_da_compra
from customer
where shipping_type in ('Standard','Express')
group by shipping_type;

--Q5. Clientes assinantes gastam mais? Compare a média e o total entre assinantes e não assinantes.
select 
	subscription_status,
	round(sum(purchase_amount),2) as gastos_totais ,
	round(avg(purchase_amount),2) as media_gastos
from customer
group by subscription_status;
--Q6. Quais 5 produtos têm a maior porcentagem de compras com desconto aplicado?
select  
	item_purchased,
	sum (case when discount_applied = 'Yes' then 1 else 0 end) * 100 / count(*) as discount_rate
from customer
GROUP BY item_purchased
ORDER BY discount_rate DESC
LIMIT 5;
-- Q7.Segmente os clientes em 'Novos', 'Recorrentes' e 'Fieis' com base no
--total de compras anteriores e mostre a contagem de cada segmento.
select  
	case 
		when previous_purchases = 1 then 'Novo'
		when previous_purchases between 2 and 10 then 'Recorrente'
		else 'Fiel'
	end as tipo_cliente,
	count(*) as total_clientes
from customer	
group by tipo_cliente
order by total_clientes desc;

--Q8. Quais são os 3 produtos mais comprados dentro de cada categoria?
WITH contagem_produtos AS (
    -- PASSO 1: Contamos quantas vezes cada produto vendeu por categoria
    SELECT 
        category, 
        item_purchased, 
        COUNT(*) AS qtd_vendas
    FROM customer
    GROUP BY category, item_purchased
),
ranking_produtos AS (
    -- PASSO 2: Criamos o ranking (1º, 2º, 3º...) dentro de cada categoria
    SELECT 
        category, 
        item_purchased, 
        qtd_vendas,
        DENSE_RANK() OVER (PARTITION BY category ORDER BY qtd_vendas DESC) AS posicao
    FROM contagem_produtos
)
-- PASSO 3: Filtramos apenas os 3 primeiros de cada "balde"
SELECT category, item_purchased, qtd_vendas
FROM ranking_produtos
WHERE posicao <= 3
ORDER BY category, qtd_vendas DESC;

--Q9. Clientes que compram repetidamente 
--(mais de 5 compras anteriores) têm mais chance de serem assinantes?
SELECT 
    CASE 
        WHEN previous_purchases > 5 THEN 'Fiel (> 5 compras)'
        ELSE 'Casual (<= 5 compras)' 
    END AS perfil_cliente,
    COUNT(*) AS total_clientes,
    SUM(CASE WHEN subscription_status = 'Yes' THEN 1 ELSE 0 END) AS total_assinantes,
    -- Calculando a taxa de conversão
    ROUND(AVG(CASE WHEN subscription_status = 'Yes' THEN 1.0 ELSE 0 END) * 100, 2) AS taxa_assinatura_pct
FROM 
    customer
GROUP BY 
    1;
--Q10 Qual é a contribuição de receita de cada faixa etária?
'Adult','Young Adult','Middle-aged','Senior'
SELECT 
    age_group,
    SUM(purchase_amount) AS receita_por_grupo,
    -- Aqui dividimos a soma do grupo pela soma total da tabela
    SUM(purchase_amount) * 100.0 / (SELECT SUM(purchase_amount) FROM customer) AS porcentagem_contribuicao
FROM 
    customer
GROUP BY 
    age_group;
--Q11 Qual a estação do ano com maior faturamento para cada gênero?
SELECT 
    gender, 
    season, 
    SUM(purchase_amount) AS Receita_Total
FROM customer
GROUP BY gender, season
ORDER BY gender, receita_Total DESC;

-- Q12 Clientes com mais de 30 compras anteriores (Fieis) preferem quais métodos de pagamento?

SELECT 
    payment_method, 
    COUNT(*) AS Total_Uso
FROM customer
WHERE previous_purchases > 30
GROUP BY payment_method
ORDER BY Total_Uso DESC;

--Q13 Existe correlação entre a frequência de compra e a nota média de avaliação?

SELECT 
    frequency_of_purchases, 
    round(AVG(review_rating)::numeric, 2) AS Media_Avaliacao, 
    COUNT(*) AS Volume_Clientes
FROM customer
GROUP BY frequency_of_purchases
ORDER BY Media_Avaliacao DESC;

--Q14: Quais são as categorias de produtos mais vendidas para a 
--"Geração Z" (clientes abaixo de 25 anos)?

SELECT 
    category, 
    COUNT(*) AS Total_Vendas,
    SUM(purchase_amount) AS Receita
FROM customer
WHERE age < 25
GROUP BY category
ORDER BY Total_Vendas DESC;

--Q15: Qual o impacto do "Shipping Type" (tipo de envio) no valor total da compra?
SELECT 
    shipping_type, 
    round(AVG(purchase_amount)::numeric,2 ) AS Ticket_Medio,
    SUM(purchase_amount) AS Faturamento_Total
FROM customer
GROUP BY shipping_type
ORDER BY Ticket_Medio DESC;
--Q16 Qual é o ciclo de retorno estimado (em dias) para cada segmento de frequência de compra?

SELECT 
    frequency_of_purchases,
    COUNT(customer_id) AS Total_Clientes,
    CASE 
        WHEN frequency_of_purchases = 'Weekly' THEN 7
        WHEN frequency_of_purchases = 'Bi-Weekly' THEN 14
        WHEN frequency_of_purchases = 'Fortnightly' THEN 15
        WHEN frequency_of_purchases = 'Monthly' THEN 30
        WHEN frequency_of_purchases = 'Quarterly' THEN 90
        WHEN frequency_of_purchases = 'Every 3 Months' THEN 90
        WHEN frequency_of_purchases = 'Annually' THEN 365
        ELSE 0 
    END AS Dias_Estimados_Retorno
FROM customer
GROUP BY frequency_of_purchases
ORDER BY Dias_Estimados_Retorno ASC;

--Q17 Como se distribui o valor de vida do cliente (LTV) acumulado por nível de fidelidade?

SELECT 
    CASE 
        WHEN previous_purchases > 30 THEN 'High LTV (Fiel Estrito)'
        WHEN previous_purchases BETWEEN 11 AND 30 THEN 'Medium LTV (Recorrente)'
        ELSE 'Low LTV (Novo/Ocasional)' 
    END AS Segmento_LTV,
    AVG(purchase_amount) AS Ticket_Medio_Atual,
    SUM(purchase_amount) AS Receita_Total_Acumulada,
    COUNT(*) AS Qtd_Clientes
FROM customer
GROUP BY Segmento_LTV
ORDER BY Receita_Total_Acumulada DESC;
select * from customer;
--Q18 Existe afinidade entre categorias de produtos específicas e métodos de pagamento 
--preferenciais?

SELECT 
    category,
    payment_method,
    COUNT(*) AS Total_Vendas,
    ROUND(AVG(review_rating)::numeric ,2) AS Nota_Media,
    SUM(purchase_amount) AS Receita_Total
FROM customer
GROUP BY category, payment_method
HAVING COUNT(*) > 10
ORDER BY Receita_Total DESC;

select * from customer;