from .base_exporter import BaseExporter

class CSVExporter(BaseExporter):
    def export(self, data, path):
        print(f"Exporting CSV to {path}")
