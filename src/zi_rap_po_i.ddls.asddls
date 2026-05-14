@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'PO Item - Interface Child View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory:   #S,
  dataClass:      #MIXED
}
define view entity ZI_RAP_PO_I
  as select from zrap_po_i
  association to parent ZI_RAP_PO_H as _Header
    on $projection.PoId = _Header.PoId
{
  key po_id                                     as PoId,
  key item_id                                   as ItemId,
      material                                  as Material,
      @Semantics.quantity.unitOfMeasure: 'Unit'
      quantity                                  as Quantity,
      @Semantics.unitOfMeasure: true
      unit                                      as Unit,
      @Semantics.amount.currencyCode: 'Currency'
      net_price                                 as NetPrice,
      @Semantics.currencyCode: true
      currency                                  as Currency,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at                     as LocalLastChangedAt,
      /* Association */
      _Header
}