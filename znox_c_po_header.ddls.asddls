@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'PO Header - Projection Root View'
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZNOX_C_PO_HEADER
  provider contract transactional_query
  as projection on ZNOX_I_PO_HEADER
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
      _Items : redirected to composition child ZNOX_C_PO_ITEM
}
