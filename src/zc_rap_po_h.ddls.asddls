@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Header - Projection Root View'
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZC_RAP_PO_H
  provider contract transactional_query
  as projection on ZI_RAP_PO_H
{
  key PoId,
      CompanyCode,
      Supplier,
      Currency,
      Status,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      LocalLastChangedAt,
      /* Composition */
      _Items : redirected to composition child ZC_RAP_PO_I
}
