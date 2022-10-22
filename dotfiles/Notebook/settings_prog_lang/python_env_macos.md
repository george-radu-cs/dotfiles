# Set up environment

1. Download and install Homebrew from <https://brew.sh>. Follow the steps it prompts you to go through after installation.
2. Download Miniforge3 (Conda installer) for macOS arm64 chips (M1, M1 Pro, M1 Max).
  <https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh>)

3. Install Miniforge3 into home directory.

```bash
chmod +x ~/Downloads/Miniforge3-MacOSX-arm64.sh
sh ~/Downloads/Miniforge3-MacOSX-arm64.sh
source ~/miniforge3/bin/activate
```

4. Restart terminal.

5. Create a directory to setup TensorFlow environment.

```bash
mkdir tensorflow-test
cd tensorflow-test
```

6. Make and activate Conda environment. **Note:** Python 3.8 is the most stable for using the following setup.

```bash
conda create --prefix ./env python=3.8
conda activate ./env
```

7. Install TensorFlow dependencies from Apple Conda channel.

```bash
 conda install -c apple tensorflow-deps
```

8. Install base TensorFlow (Apple's fork of TensorFlow is called `tensorflow-macos`).

```bash
python -m pip install tensorflow-macos
```

9. Install Apple's `tensorflow-metal` to leverage Apple Metal (Apple's GPU framework) for M1, M1 Pro, M1 Max GPU acceleration.

```bash
python -m pip install tensorflow-metal
```

10. (Optional) Install TensorFlow Datasets to run benchmarks included in this repo.

```bash
python -m pip install tensorflow-datasets
```

11. Install common data science packages.

```bash
conda install jupyter pandas numpy matplotlib scikit-learn
```

12. Start Jupyter Notebook.

```bash
jupyter notebook
```

13. Import dependencies and check TensorFlow version/GPU access.

```python
import numpy as np
import pandas as pd
import sklearn
import tensorflow as tf
import matplotlib.pyplot as plt

# Check for TensorFlow GPU access
print(f"TensorFlow has access to the following devices:\n{tf.config.list_physical_devices()}")

# See TensorFlow version
print(f"TensorFlow version: {tf.__version__}")
```

If it all worked, you should see something like:

```python
TensorFlow has access to the following devices:
[PhysicalDevice(name='/physical_device:CPU:0', device_type='CPU'),
PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]
TensorFlow version: 2.8.0
```
