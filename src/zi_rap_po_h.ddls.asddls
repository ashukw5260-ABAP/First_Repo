@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #CHECK
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
      @Semantics.currencyCode: true
      currency              as Currency,
      status                as Status,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      /* Association */
      _Items
}