"""Base exporter class"""

class BaseExporter:
    def export(self, data, path):
        raise NotImplementedError
