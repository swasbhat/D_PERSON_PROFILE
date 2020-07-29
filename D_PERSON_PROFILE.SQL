
-----------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------
---The Detail information of this Denorm was included in the below wiki Link
-- Wiki Link : https://w.amazon.com/bin/view/Pandora_Data_Platform/Content/SubjectAreas/Person_Profile/
------------------------------------------------------------------------------------------------------------------------------------
-- Target table: D_PERSON_PROFILE
-- Primary Key : Person_ID, Customer_ID
-- Partition Key : TBD

------------------------------------------------------------------------------------------------------------------------------------


--This is the base CTE for finding the latest record in O_PHARMACYDEMOGRAPHICPROFILES for each Person_id

with Deomographic_profile as (
  Select
    PERSONID as PERSON_ID,
    (CONVERT_TIMEZONE('America/Los_Angeles', 'UTC', LOADED_AT)) as LOADED_AT
  from
    (
      SELECT
        PERSONID,
        LOADED_AT,
        Row_number() OVER (
          partition BY PERSONID
          ORDER BY
            LOADED_AT desc
        ) AS rank_num
      FROM
        "AP_INGEST_PROD"."APEX_PROD"."O_PHARMACYDEMOGRAPHICPROFILES"
      WHERE
        compositeID LIKE 'PR|DP' --- To Filter out DP stands for Demographic Profile dataset
    ) DP
  where
    DP.rank_num = 1
),


--This is the  CTE for finding the latest first Order_date each Person_id, this will be replaced by D_CUSTOMER_ORDER_ITEMS 
Ordering as (
  SELECT
    apex_users.PERSON_ID,
    (CONVERT_TIMEZONE('America/Los_Angeles','UTC',MIN (SENT_TO_PHAROS_AT))) as FIRST_ORDER_PLACED_DATETIME 
  FROM
    source_pillpack_core.shipments shipments
    LEFT JOIN "PRODUCTION"."PANDORA"."APEX_USERS" apex_users ---- To get the PERSON_ID Value since Shipments does not have this column
    on shipments.user_id = apex_users.user_id
  WHERE
    deleted = FALSE
    and amazon_pharmacy_order_id IS NOT NULL
  group by
    1
) 



------FINAL SELECT FOR D_PERSON_PROFILE
Select
  Deomographic_profile.PERSON_ID as PERSON_ID,
  FIRST_ORDER_PLACED_DATETIME,
  'UTC' as Timezone
from
  Deomographic_profile
  left join Ordering on Ordering.PERSON_ID = Deomographic_profile.PERSON_ID


  
  
  