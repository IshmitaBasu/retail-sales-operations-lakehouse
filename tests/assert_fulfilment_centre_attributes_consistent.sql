select fulfilment_centre_id
from {{ ref('view_fulfilments') }}
group by fulfilment_centre_id
having count(distinct fulfilment_centre_name) != 1
    or count(distinct fulfilment_centre_region) != 1
