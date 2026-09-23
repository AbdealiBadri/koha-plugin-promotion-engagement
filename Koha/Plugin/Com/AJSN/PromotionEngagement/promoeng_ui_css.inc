[% USE raw %]
[% USE Asset %]
[% Asset.css("lib/select2/css/select2.min.css") | $raw %]
[% Asset.css("css/select2.css") | $raw %]
[% Asset.css("lib/d3c3/c3.min.css") | $raw %]
<style>
/* v0.6 shared Promotion & Engagement interface components */
.promo-howto-control{text-align:right;margin:0 0 10px}.promo-help-button{margin-left:8px}
.promo-howto{display:none;border:1px solid #b8cbd2;border-left:5px solid #2d7372;border-radius:7px;background:#f8fbfb;padding:18px 20px;margin:0 0 20px;box-shadow:0 2px 8px rgba(23,50,77,.06)}
.promo-howto.is-open{display:block}
.promo-howto h2{font-family:Georgia,serif;color:#17324d;margin:0 0 12px;font-size:1.45rem}
.promo-howto h3{color:#245b64;margin:16px 0 7px;font-size:1.08rem}
.promo-howto ol,.promo-howto ul{margin-bottom:8px}.promo-howto li{margin-bottom:5px}
.promo-howto .promo-help-note{background:#eef5f5;border-left:4px solid #3d6685;padding:10px 12px;margin:12px 0}
.promo-howto .promo-help-warning{background:#fff8e7;border-left:4px solid #b28b32;padding:10px 12px;margin:12px 0}
.promo-howto .promo-help-simple{font-size:1.02rem;color:#294d5b}
.promo-toolbar-spread{display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap}
.promo-toolbar-spread .btn-toolbar{margin-bottom:0}
.promo-section-card{background:#fff;border:1px solid #d8e1e5;border-radius:8px;box-shadow:0 2px 9px rgba(23,50,77,.06);margin-bottom:18px;overflow:hidden}
.promo-section-card>.promo-section-head{background:#f1f5f6;border-bottom:1px solid #d8e1e5;padding:13px 16px;display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap}
.promo-section-card>.promo-section-head h2,.promo-section-card>.promo-section-head h3{margin:0;color:#17324d;font-family:Georgia,serif}
.promo-section-card>.promo-section-body{padding:16px}
.metric-card{background:#fff;border:1px solid #d9e2e6;border-top:4px solid #b28b32;border-radius:8px;padding:16px 17px;min-height:116px;margin-bottom:18px;box-shadow:0 3px 10px rgba(23,50,77,.09);position:relative;overflow:hidden}
.metric-card.teal{border-top-color:#2d7372}.metric-card.blue{border-top-color:#3d6685}
.metric-card .metric-label{color:#526b78;text-transform:uppercase;letter-spacing:.04em;font-size:.76rem;font-weight:700}
.metric-card .metric-value{font-family:Georgia,serif;color:#17324d;font-size:2.05rem;line-height:1.15;margin:6px 0 3px}
.metric-card .metric-help,.metric-card .text-muted{color:#6c8189;font-size:.84rem}
.promo-kpi-clickable{cursor:pointer;transition:transform .12s ease,box-shadow .12s ease}
.promo-kpi-clickable:hover,.promo-kpi-clickable:focus{transform:translateY(-2px);box-shadow:0 5px 14px rgba(23,50,77,.15)!important;outline:2px solid rgba(45,115,114,.18)}
.promo-kpi-clickable .promo-drilldown-hint{display:block;margin-top:5px;color:#607780;font-size:.78rem}
.promo-kpi-clickable .promo-drilldown-hint:before{content:"\f0a6";font-family:FontAwesome;margin-right:4px}
.promo-table-wrap{position:relative}
.promo-table-active-filter{display:none;background:#e8f3f2;border:1px solid #b7d4d0;border-radius:5px;padding:8px 10px;margin:0 0 10px;color:#17324d}
.promo-table-active-filter.is-visible{display:flex;justify-content:space-between;gap:10px;align-items:center}
.promo-filter-highlight>td{background:#fff7d6!important;box-shadow:inset 0 1px 0 #e2c675,inset 0 -1px 0 #e2c675}
.promo-filter-token{display:none!important}
.promo-quick-filters{display:flex;gap:6px;flex-wrap:wrap;margin:0 0 12px}
.promo-quick-filters .btn.active{background:#245b64!important;color:#fff!important;border-color:#1c4d55!important}
.promo-chart-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:16px;margin:0 0 18px}
.promo-chart-card{background:#fff;border:1px solid #d8e1e5;border-radius:8px;padding:14px 14px 10px;box-shadow:0 2px 8px rgba(23,50,77,.06)}
.promo-chart-card h3{font-family:Georgia,serif;color:#17324d;font-size:1.1rem;margin:0 0 4px}
.promo-chart-card p{color:#607780;font-size:.88rem;margin:0 0 8px}
.promo-chart{min-height:270px}
.promo-chart-actions{display:flex;justify-content:flex-end;margin-top:6px}
.promo-view-toggle{display:flex;gap:6px;flex-wrap:wrap}
.promo-view-panel{display:none}.promo-view-panel.is-active{display:block}
.promo-signal-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px}
.promo-signal-card{border:1px solid #d8e1e5;border-radius:8px;background:#fff;padding:15px;min-height:112px;position:relative;box-shadow:0 2px 8px rgba(23,50,77,.06)}
.promo-signal-card .signal-icon{font-size:1.4rem;color:#2d7372;margin-bottom:6px}
.promo-signal-card .signal-label{color:#526b78;text-transform:uppercase;font-size:.76rem;font-weight:700;letter-spacing:.04em}
.promo-signal-card .signal-value{font-family:Georgia,serif;color:#17324d;font-size:2rem;line-height:1.2;margin:5px 0}
.promo-signal-card .signal-help{font-size:.83rem;color:#6d8189}
.promo-row-top-issuing>td{background:#edf8f2!important}
.promo-row-zero-response>td{background:#fff0f0!important}
.promo-response-legend{display:flex;gap:16px;flex-wrap:wrap;margin:0 0 10px;color:#526b78;font-size:.86rem}
.promo-response-legend .legend-swatch{display:inline-block;width:13px;height:13px;border:1px solid #aab9bf;border-radius:2px;vertical-align:-2px;margin-right:4px}
.promo-response-legend .legend-top{background:#edf8f2}.promo-response-legend .legend-zero{background:#fff0f0}
.promo-status-note{display:inline-flex;align-items:center;gap:5px;font-size:.8rem;font-weight:700;border-radius:12px;padding:3px 8px}
.promo-status-note.success{background:#e4f2ed;color:#225c49}.promo-status-note.danger{background:#f9e4e4;color:#8a2f39}
.promo-status-note.info{background:#e7f0f5;color:#315c72}
.promo-select-row{display:flex;align-items:flex-end;gap:10px;flex-wrap:wrap}
.promo-select-row .promo-select-field{min-width:260px;flex:1}
.promo-select-row .select2-container{width:100%!important}
.select2-container--default .select2-selection--multiple,.select2-container--default .select2-selection--single{border-color:#91a5ad;min-height:36px}
.select2-container--default.select2-container--focus .select2-selection--multiple,.select2-container--default.select2-container--focus .select2-selection--single{border-color:#2d7372;box-shadow:0 0 0 2px rgba(45,115,114,.15)}
.promo-muted-academic{color:#607780;font-size:.9rem}
.promo-analytics-header{display:grid;grid-template-columns:minmax(0,1fr) auto;gap:16px;align-items:start;margin:0 0 14px}
.promo-analytics-header h2{margin:0 0 5px;color:#17324d;font-family:Georgia,serif}
.promo-analytics-meta{display:flex;gap:8px;flex-wrap:wrap}
.promo-meta-pill{display:inline-block;background:#eef3f5;border:1px solid #d3dfe3;border-radius:14px;padding:4px 9px;font-size:.82rem;color:#355460}
.promo-dt-note{font-size:.82rem;color:#607780;margin-top:6px}
@media(max-width:767px){.promo-analytics-header{grid-template-columns:1fr}.promo-chart-grid{grid-template-columns:1fr}.promo-select-row{display:block}.promo-select-row>*{margin-bottom:8px}}
</style>
