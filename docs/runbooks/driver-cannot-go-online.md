# A distributor can't go online or sees no orders

Start with their phone number.

```sql
select p.id, p.role, p.is_active, d.is_verified, d.is_online,
       d.lat, d.lng, d.location_updated_at, d.cylinders_on_board
  from profiles p left join drivers d on d.id = p.id
 where p.phone = '+962791234567';
```

| What you see | Cause | Fix |
|---|---|---|
| `role` = customer, no drivers row | Signed up in the customer app | Create a new account in the distributor app |
| `is_verified` = false | Not approved yet | Verify their documents, then `update drivers set is_verified = true where id = '<id>';` |
| `is_active` = false | Account suspended | Staff decision |
| Switch shows an error about location | Location permission or GPS off | Phone settings › Apps › ClickGas Driver › Location: Allow |
| Online but `location_updated_at` old | Battery saver killed the app | Exclude the app from battery optimisation |
| Online, fresh location, still no orders | No pending orders within 2 km | Normal; see [order-stuck.md](order-stuck.md) from the order side |

If none apply, ask them to **Send diagnostics** and read it with
[diagnostics.md](diagnostics.md).
