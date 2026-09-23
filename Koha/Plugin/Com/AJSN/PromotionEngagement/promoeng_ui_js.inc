[% USE raw %]
[% USE Asset %]
[% INCLUDE 'datatables.inc' %]
[% Asset.js("lib/select2/js/select2.min.js") | $raw %]
[% Asset.js("js/select2.js") | $raw %]
[% Asset.js("lib/d3c3/d3.min.js") | $raw %]
[% Asset.js("lib/d3c3/c3.min.js") | $raw %]
<script>
(function($){
    "use strict";

    function naturalText(value){
        return (value || "").toString().trim();
    }

    function naturalCompare(a,b){
        return naturalText(a.text).localeCompare(naturalText(b.text), undefined, {numeric:true, sensitivity:"base"});
    }

    function initSearchableSelects(){
        $(".promo-searchable-select").each(function(){
            var $select = $(this);
            if ($select.hasClass("select2-hidden-accessible")) return;
            var options = {
                width: "100%",
                placeholder: $select.data("placeholder") || "Search and select",
                allowClear: $select.data("allow-clear") !== false
            };
            if ($select.data("natural-sort")) {
                options.sorter = function(data){ return data.sort(naturalCompare); };
            }
            $select.select2(options);
        });
    }

    function initTables(){
        $("table.promo-data-table").each(function(){
            var $table = $(this);
            if ($.fn.DataTable.isDataTable(this)) return;
            var length = parseInt($table.data("page-length"),10);
            if (!length || length < 1) length = 25;
            var order = [];
            var orderColumn = $table.data("order-column");
            var orderDirection = $table.data("order-direction") || "asc";
            if (orderColumn !== undefined && orderColumn !== "") {
                order = [[parseInt(orderColumn,10), orderDirection]];
            }
            var dt = $table.kohaTable({
                paging: $table.data("paging") === false ? false : true,
                pageLength: length,
                searching: true,
                info: true,
                autoWidth: false,
                order: order,
                stateSave: false
            });
            $table.data("promo-dt", dt);
        });
    }

    function getTable(target){
        var $table = $(target);
        if (!$table.length) return null;
        if (!$.fn.DataTable.isDataTable($table[0])) initTables();
        return $table.DataTable();
    }

    window.promoFilterTable = function(target, term, label){
        var dt = getTable(target);
        if (!dt) return;
        dt.search(term || "").draw();
        var $table = $(target);
        $table.find("tbody tr").removeClass("promo-filter-highlight");
        if (term) {
            $(dt.rows({search:"applied", page:"current"}).nodes()).addClass("promo-filter-highlight");
        }
        var $notice = $table.closest(".promo-table-wrap").find(".promo-table-active-filter");
        if ($notice.length) {
            if (term) {
                $notice.addClass("is-visible").find(".promo-filter-label").text(label || term);
            } else {
                $notice.removeClass("is-visible").find(".promo-filter-label").text("");
            }
        }
        $("html,body").animate({scrollTop:$table.offset().top - 120}, 250);
    };

    window.promoClearTableFilter = function(target){
        promoFilterTable(target, "", "");
    };

    function initKpiDrilldowns(){
        $(document).on("click keydown", "[data-promo-table-filter]", function(e){
            if (e.type === "keydown" && e.key !== "Enter" && e.key !== " ") return;
            e.preventDefault();
            var $el = $(this);
            var target = $el.data("promo-table-filter");
            var $panel = $(target).closest(".promo-view-panel");
            if ($panel.length && !$panel.hasClass("is-active")) {
                var group = $panel.data("promo-view-panel");
                $("[data-promo-view-panel='"+group+"']").removeClass("is-active");
                $panel.addClass("is-active");
                $("[data-promo-view-group='"+group+"']").removeClass("active");
                $("[data-promo-view-show='#"+$panel.attr("id")+"']").addClass("active");
                if ($.fn.DataTable.isDataTable($(target)[0])) $(target).DataTable().columns.adjust();
            }
            promoFilterTable(target, $el.data("promo-filter-term"), $el.data("promo-filter-label"));
        });
        $(document).on("click", "[data-promo-clear-filter]", function(){
            promoClearTableFilter($(this).data("promo-clear-filter"));
        });
    }

    function initHelp(){
        $(document).on("click", "[data-promo-help-toggle]", function(){
            var target = $(this).data("promo-help-toggle");
            var $panel = $(target);
            $panel.toggleClass("is-open");
            $(this).attr("aria-expanded", $panel.hasClass("is-open") ? "true" : "false");
            if ($panel.hasClass("is-open")) {
                $("html,body").animate({scrollTop:$panel.offset().top - 110}, 200);
            }
        });
    }

    function initViewToggles(){
        $(document).on("click", "[data-promo-view-show]", function(){
            var $btn = $(this);
            var group = $btn.data("promo-view-group");
            var show = $btn.data("promo-view-show");
            $("[data-promo-view-panel='"+group+"']").removeClass("is-active");
            $(show).addClass("is-active");
            $("[data-promo-view-group='"+group+"']").removeClass("active");
            $btn.addClass("active");
            if ($(show).find("table.promo-data-table").length) {
                $(show).find("table.promo-data-table").each(function(){
                    if ($.fn.DataTable.isDataTable(this)) $(this).DataTable().columns.adjust();
                });
            }
        });
    }

    window.promoMakeBarChart = function(id, categories, columns, options){
        options = options || {};
        var node = document.getElementById(id);
        if (!node || typeof c3 === "undefined") return null;
        node.innerHTML = "";
        var chart = c3.generate({
            bindto: "#" + id,
            size: {height: options.height || 285},
            data: {
                columns: columns,
                type: "bar",
                labels: true,
                order: null
            },
            axis: {
                x: {
                    type: "category",
                    categories: categories,
                    tick: {rotate: categories.length > 6 ? -35 : 0, multiline:false, culling:{max:12}},
                    height: categories.length > 6 ? 70 : 45
                },
                y: {min:0, padding:{bottom:0}}
            },
            bar: {width:{ratio: options.barRatio || 0.58}},
            legend: {position:"bottom"},
            grid: {y:{show:true}},
            tooltip: {grouped:true},
            color: {pattern: options.colors || ["#245b64","#b28b32","#3d6685","#2d7372","#8a2f39"]}
        });
        node._promoChart = chart;
        return chart;
    };

    window.promoMakeDonutChart = function(id, columns, options){
        options = options || {};
        var node = document.getElementById(id);
        if (!node || typeof c3 === "undefined") return null;
        node.innerHTML = "";
        var chart = c3.generate({
            bindto: "#" + id,
            size: {height: options.height || 285},
            data: {columns:columns, type:"donut", order:null},
            donut: {
                title: options.title || "",
                label: {show:true, format:function(value,ratio){return Math.round(ratio*100)+"%";}}
            },
            legend: {position:"bottom"},
            color: {pattern: options.colors || ["#2d7372","#b28b32","#8a2f39","#3d6685"]}
        });
        node._promoChart = chart;
        return chart;
    };

    window.promoDownloadChartJpeg = function(id, filename){
        var container = document.getElementById(id);
        if (!container) return;
        var svg = container.querySelector("svg");
        if (!svg) return;
        var clone = svg.cloneNode(true);
        clone.setAttribute("xmlns","http://www.w3.org/2000/svg");
        var serializer = new XMLSerializer();
        var source = serializer.serializeToString(clone);
        var img = new Image();
        var blob = new Blob([source], {type:"image/svg+xml;charset=utf-8"});
        var url = URL.createObjectURL(blob);
        img.onload = function(){
            var scale = 2;
            var width = Math.max(svg.getBoundingClientRect().width, 640);
            var height = Math.max(svg.getBoundingClientRect().height, 300);
            var canvas = document.createElement("canvas");
            canvas.width = width * scale;
            canvas.height = height * scale;
            var ctx = canvas.getContext("2d");
            ctx.scale(scale,scale);
            ctx.fillStyle = "#ffffff";
            ctx.fillRect(0,0,width,height);
            ctx.drawImage(img,0,0,width,height);
            URL.revokeObjectURL(url);
            var link = document.createElement("a");
            link.download = (filename || "promotion-chart") + ".jpg";
            link.href = canvas.toDataURL("image/jpeg",0.94);
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        };
        img.src = url;
    };

    window.promoChartFromComparisonTable = function(tableSelector, chartId, options){
        options = options || {};
        var table = document.querySelector(tableSelector);
        if (!table) return;
        var labels=[], baseline=[], campaign=[];
        var rows;
        if ($.fn.DataTable.isDataTable(table)) {
            rows = $(table).DataTable().rows({search:"applied"}).nodes().toArray();
        } else {
            rows = Array.prototype.slice.call(table.querySelectorAll("tbody tr"));
        }
        rows.forEach(function(row){
            if (row.querySelectorAll("td").length < 7) return;
            labels.push(row.cells[0].innerText.trim().split("\n")[0]);
            baseline.push(parseFloat(row.cells[5].innerText.replace(/[^0-9.-]/g,"")) || 0);
            campaign.push(parseFloat(row.cells[6].innerText.replace(/[^0-9.-]/g,"")) || 0);
        });
        promoMakeBarChart(chartId, labels, [["Baseline checkouts"].concat(baseline),["Campaign checkouts"].concat(campaign)], options);
    };

    function initQuickFilters(){
        $(document).on("click", ".promo-quick-filters [data-promo-quick-filter]", function(){
            var $btn=$(this);
            var target=$btn.data("promo-quick-target");
            var term=$btn.data("promo-quick-filter");
            var label=$btn.text().trim();
            $btn.closest(".promo-quick-filters").find(".btn").removeClass("active");
            $btn.addClass("active");
            promoFilterTable(target, term, label);
        });
    }

    function initCampaignComparisonButtons(){
        $(document).on("click", "[data-promo-compare-selected]", function(){
            var $button=$(this);
            var select=$button.data("promo-compare-selected");
            var values=$(select).val() || [];
            if (!Array.isArray(values)) values=[values];
            values=values.filter(Boolean);
            if (values.length < 1) {
                alert("Select at least one campaign first.");
                return;
            }
            var params=new URLSearchParams();
            params.set("class", $button.data("class"));
            params.set("method", $button.data("method"));
            params.set("action", "reports");
            values.forEach(function(value){ params.append("campaign_ids", value); });
            window.location.href="/cgi-bin/koha/plugins/run.pl?"+params.toString();
        });
    }

    $(document).ready(function(){
        initSearchableSelects();
        initTables();
        initKpiDrilldowns();
        initHelp();
        initViewToggles();
        initQuickFilters();
        initCampaignComparisonButtons();
    });
})(jQuery);
</script>
