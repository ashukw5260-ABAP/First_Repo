@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Item - Projection Child View'
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
define view entity ZC_RAP_PO_I
  as projection on ZI_RAP_PO_I
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
      _Header : redirected to parent ZC_RAP_PO_H
}
