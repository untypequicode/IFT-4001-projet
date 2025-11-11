from .csv_exporter import CSVExporter
from .excel_exporter import ExcelExporter
from .html_exporter import HTMLExporter
from .latex_exporter import LaTeXExporter

def get_exporter(kind):
    return {
        'csv': CSVExporter(),
        'excel': ExcelExporter(),
        'html': HTMLExporter(),
        'latex': LaTeXExporter()
    }[kind]
