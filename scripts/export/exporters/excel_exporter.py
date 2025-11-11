from .base_exporter import BaseExporter

class ExcelExporter(BaseExporter):
    def export(self, data, path):
        print(f"Exporting Excel to {path}")
