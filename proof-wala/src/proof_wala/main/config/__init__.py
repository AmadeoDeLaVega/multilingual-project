"""Compatibility exports for the adjacent training config parser.

This package exists so Hydra can load YAML files from ``main/config``.  The
training entrypoints also import ``proof_wala.main.config`` expecting the
adjacent ``main/config.py`` module, so re-export its public parser symbols here.
"""

from importlib import util
from pathlib import Path

_CONFIG_MODULE_PATH = Path(__file__).resolve().parent.parent / "config.py"
_SPEC = util.spec_from_file_location("_proof_wala_main_config_file", _CONFIG_MODULE_PATH)
if _SPEC is None or _SPEC.loader is None:
    raise ImportError(f"Could not load training config module at {_CONFIG_MODULE_PATH}")

_MODULE = util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(_MODULE)

EvalSettings = _MODULE.EvalSettings
Experiment = _MODULE.Experiment
ExperimentType = _MODULE.ExperimentType
ModelSettings = _MODULE.ModelSettings
TrainingDataFormatterType = _MODULE.TrainingDataFormatterType
TrainingDataSettings = _MODULE.TrainingDataSettings
TrainingDatasetType = _MODULE.TrainingDatasetType
TrainingSettings = _MODULE.TrainingSettings
parse_config = _MODULE.parse_config
recursive_replace_keywords = _MODULE.recursive_replace_keywords

__all__ = [
    "EvalSettings",
    "Experiment",
    "ExperimentType",
    "ModelSettings",
    "TrainingDataFormatterType",
    "TrainingDataSettings",
    "TrainingDatasetType",
    "TrainingSettings",
    "parse_config",
    "recursive_replace_keywords",
]
