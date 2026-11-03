select distinct
    fulfilment_centre_id,
    fulfilment_centre_name,
    fulfilment_centre_region
from {{ ref('view_fulfilments') }}
