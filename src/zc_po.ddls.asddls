@EndUserText.label: 'PO Header Projection'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define root view entity ZC_PO
  provider contract transactional_query
  as projection on ZI_PO
{
  key po_id,
      vendor_id,
      doc_date,
      currency,
      status,
      created_by,
      created_at,
      changed_by,
      changed_at,
      _Items: redirected to ZC_PO_ITEM
}