@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'PO Item Interface View'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_PO_ITEM
  as select from zpo_itm
  association to parent ZI_PO as _PO
    on  $projection.PO_ID = _PO.PO_ID
{
  key po_id      as PO_ID,
  key item_no    as ITEM_NO,
      material   as MATERIAL,
      quantity   as QUANTITY,
      uom        as UOM,
      net_price  as NET_PRICE,
      currency   as CURRENCY,
      plant      as PLANT,
      created_by as CREATED_BY,
      created_at as CREATED_AT,
      changed_by as CHANGED_BY,
      changed_at as CHANGED_AT,
      _PO
}
where
  is_deleted = ' '