# Glossary

| English | العربية | In code | Notes |
|---|---|---|---|
| Customer | عميل / زبون | `customer` | Orders gas |
| Distributor | موزع | `driver` | Delivers gas; "driver" in code and database |
| Distribution agency | وكالة التوزيع | `agency_name` | The gas company a distributor works with |
| Gas cylinder | جرة / أسطوانة غاز | `quantity` | Household LPG cylinder, 12.5 kg in Jordan |
| Cylinder exchange | استبدال جرة | service `exchange` | Empty cylinder swapped for a full one |
| New cylinder | جرة جديدة | service `new_cylinder` | Steel cylinder bought with gas |
| Cylinders on board | الجرات في المركبة | `cylinders_on_board` | Stock on the truck |
| Online / offline | متصل / غير متصل | `is_online` | Distributor is receiving orders |
| Verified | موثّق | `is_verified` | Approved by staff |
| Order statuses | حالات الطلب | `order_status` | pending بانتظار موزع · accepted مقبول · on_the_way في الطريق · delivered تم التوصيل · cancelled ملغي · expired انتهت المهلة |
| Release (give back) | إلغاء من الموزع | `release_order` | Order returns to other distributors |
| Confirm receipt | تأكيد الاستلام | `confirm_delivery` | Customer confirms after delivery |
| Service fee | رسوم الخدمة | `service_fee` | 0.100 JOD paid by the customer |
| Distributor fee | رسوم الموزع | `driver_fee` | 0.050 JOD paid by the distributor |
| Ledger | سجل المستحقات | `driver_ledger` | What a distributor owes the platform |
| Jordanian dinar | دينار أردني (د.أ) | JOD | 1 JOD = 100 piasters = 1,000 fils |
| Piaster | قرش | - | 0.010 JOD; the fee is 15 piasters |
| Fils | فلس | - | 0.001 JOD; money keeps 3 decimals |
| Dispatch radius | نطاق التوزيع | `driver_radius_km` | 2 km |
| Diagnostics | تقرير تشخيص | `diagnostics` | Log upload for support |
| CliQ | كليك | - | Jordan's instant bank transfer (postponed) |
| Zain Cash | زين كاش | - | Mobile wallet (postponed) |
