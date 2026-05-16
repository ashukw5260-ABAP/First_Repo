@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'PO Item - Projection Child View'
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
define view entity ZNOX_C_PO_ITEM
  as projection on ZNOX_I_PO_ITEM
{
  key PoId,
  key ItemId,
      Material,
      @Semantics.quantity.unitOfMeasure: 'Unit'
      Quantity,
      Unit,
      @Semantics.amount.currencyCode: 'Currency'
      NetPrice,
      Currency,
      LocalLastChangedAt,
      /* Association */
      _Header : redirected to parent ZNOX_C_PO_HEADER
}
