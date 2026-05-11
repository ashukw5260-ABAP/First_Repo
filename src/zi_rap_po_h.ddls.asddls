@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PO Header - Interface Root View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
  serviceQuality: #X,
  sizeCategory:   #S,
  dataClass:      #MIXED
}
define root view entity ZI_RAP_PO_H
  as select from zrap_po_h
  composition [0..*] of ZI_RAP_PO_I as _Items
{
  key po_id                 as PoId,
      company_code          as CompanyCode,
      supplier              as Supplier,
    //  @Semantics.currencyCode: true
      currency              as Currency,
      status                as Status,
      created_by            as CreatedBy,
      created_at            as CreatedAt,
      last_changed_by       as LastChangedBy,
      last_changed_at       as LastChangedAt,
      local_last_changed_at as LocalLastChangedAt,
      /* Association */
      _Items
}
