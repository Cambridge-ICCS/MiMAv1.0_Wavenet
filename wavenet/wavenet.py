import os
import pickle
import time
import traceback
from typing import Any, Dict, Union

import tensorflow as tf
import numpy as np
"""
Choose input features from union of:
------------------------------------
# WaveNet ["temp", "hght", "ucomp", "vcomp", "omega", "slp", "lat", "lon"]
# MiMA ["lat", "lon", "pfull", "zfull", "temp", "uuu", "vvv", "time", "delt"]
"""
features_gwfu = ["uuu", "temp"]
features_gwfv = ["vvv", "temp"]
model_path = '/scratch/users/mborrus/MiMA/code/MiMAv0.1_mborrus/wavenet/models/wind_temp'# Local Testing: './models/wind_temp/'

#features_gwfu = ["temp", "uuu", "vvv", "lat", "lon"]
#features_gwfv = ["temp", "uuu", "vvv", "lat", "lon"]
#model_path = '/home/zespinos/models/uv_temp'# Local Testing: './models/wind_temp/'
ZERO_LAYERS = 7

# Set memory growth for GPUs
gpus = tf.config.list_physical_devices('GPU')
for gpu in gpus:
    try:
          tf.config.experimental.set_memory_growth(gpu, True)
    except:
          # Invalid device or cannot modify virtual devices once initialized.
            pass

def init_wavenet():
    global wavenet_gwfu
    global wavenet_gwfv
    global scaler_gwfu
    global scaler_gwfv
    global scaler_tensors

    # Load Scalars Once
    try:
        scaler_gwfu = from_pickle(os.path.join(model_path, 'scaler_gwfu.pkl'))
        scaler_gwfv = from_pickle(os.path.join(model_path, 'scaler_gwfv.pkl'))
        scaler_tensors = from_pickle(os.path.join(model_path, 'scaler_tensors.pkl'))
        # Load Model Once
        wavenet_gwfu = tf.keras.models.load_model(os.path.join(model_path, 'wavenet_gwfu.hdf5'), compile=False)
        wavenet_gwfv = tf.keras.models.load_model(os.path.join(model_path, 'wavenet_gwfv.hdf5'), compile=False)
        wavenet_gwfu.compile(loss='logcosh', optimizer="adam")
        wavenet_gwfv.compile(loss='logcosh', optimizer="adam")
        wavenet_gwfu.summary()
    except Exception as e:
        handle_errors(e)


def build_input_tensors(model: str, args: Dict[str, np.ndarray]):
    if model == 'gwfu':
        features = features_gwfu
        output_scaler = scaler_gwfu
    else:
        features = features_gwfv
        output_scaler = scaler_gwfv

    tensors = [args[feat].reshape(args[feat].shape[0]*args[feat].shape[1], args[feat].shape[2]) for feat in features]
    tensors = np.concatenate(tensors, axis=1)
    tensors = scaler_tensors.transform(tensors)

    return tensors


def from_pickle(path: Union[str, os.PathLike]) -> Any:
    try:
        with open(path, 'rb') as handle:
            b = pickle.load(handle)
    except:
        traceback.print_exc()
    else:
        return b


def handle_errors(e):
    print("#### SOMETHING WENT WRONG #### ")
    print(e)
    traceback.print_exc()
    output = open("errors.txt", "a+")
    output.write(f"GWFU: {e} \n")
    output.close()


def generate_predictions(wavenet, scaler, tensors, args):
    # Adding zeros to end (i.e. assuming 0 index is top [.18hPa] and 33 is bottom [475hPa])

    predictions = wavenet.predict(tensors)
    predictions = np.hstack(predictions)
    predictions = scaler.inverse_transform(predictions)
    predictions = np.concatenate(
        (predictions, np.zeros((predictions.shape[0], ZERO_LAYERS))),
        axis=1
    )
    predictions = predictions.reshape(args[6].shape)
    predictions = np.asfortranarray(predictions)

    return predictions


def predict_u(*args):
    """
    Arguments:
    ----------
        is:
        js:
        lat:
        pfull:
        zfull:
        temp:
        uuu:
        vvv:
        time:
        delt:
        gwfcng_x:
        gwfcng_y:

    Returns:
    --------
        gwfu:
    """

    ## DEBUGGING ##
    #os.system("cat /proc/meminfo")
    ## DEBUGGING ##

    try:
        # Build Input Vectors
        tensors = build_input_tensors(
            model="gwfu",
            args={
                'temp': args[5],  # temp
                'zfull': args[4], # zfull
                'uuu': args[6],   # uuu
                'vvv': args[7],   # vvv
                'lat': args[0],   # lat
                'lon': args[1],   # lon
            }
        )

        # RUN-TIME TESTING
        #predictions = np.full(args[6].shape, 10e-5)
        #predictions = np.asfortranarray(predictions)
        #return predictions
        ########

        # Generate Predictions
        predictions = generate_predictions(
            wavenet=wavenet_gwfu,
            scaler=scaler_gwfu,
            tensors=tensors,
            args=args,
        )
    except Exception as e:
        handle_errors(e)
    else:
        return predictions


def predict_v(*args):
    try:
        # Build Input Vectors
        tensors = build_input_tensors(
            model="gwfv",
            args={
                'temp': args[5],  # temp
                'zfull': args[4], # zfull
                'uuu': args[6],   # uuu
                'vvv': args[7],   # vvv
                'lat': args[0],   # lat
                'lon': args[1],   # lon
            }
        )

        # RUN-TIME TESTING
        #predictions = np.full(args[6].shape, 10e-5)
        #predictions = np.asfortranarray(predictions)
        #return predictions
        ########

        # Generate Predictions
        predictions = generate_predictions(
            wavenet=wavenet_gwfv,
            scaler=scaler_gwfv,
            tensors=tensors,
            args=args,
        )
        return predictions
    except Exception as e:
        handle_errors(e)
    else:
        return predictions


###### Development Testing Only #####
def local_testing():
    dd_args = from_pickle(os.path.join('./dd_args', 'args.pkl'))
    gwfu = predict_u(*list(dd_args.values()))
    gwfv = predict_v(*list(dd_args.values()))
    print(gwfu[0])
#####################################
#init_wavenet()
#local_testing()
