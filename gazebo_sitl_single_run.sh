#!/bin/bash
# run multiple instances of the 'px4' binary, with the gazebo SITL simulation
# It assumes px4 is already built, with 'make px4_sitl_default gazebo'
# PX4仿真器默认发送的TCP端口为4560
# gazebo运行单机示例：
# ./Tools/gazebo_sitl_single_run.sh -m alex_iris_realsense_d435
# ./Tools/gazebo_sitl_single_run.sh -m alex_iris_realsense_d435 -w baylands

function cleanup() {
	pkill -x px4
	pkill gzclient
	pkill gzserver
}

function spawn_model() {
	MODEL=$1
	N=$2 #Instance Number
	X=$3
	Y=$4
	X=${X:=0.0}
	Y=${Y:=0.0}
	MODEL_SDF=$5

	SUPPORTED_MODELS=("iris" "alex_iris" "plane" "standard_vtol" "rover" "r1_rover" "typhoon_h480")
	if [[ " ${SUPPORTED_MODELS[*]} " != *"$MODEL"* ]];
	then
		echo "ERROR: Currently only vehicle model $MODEL is not supported!"
		echo "       Supported Models: [${SUPPORTED_MODELS[@]}]"
		trap "cleanup" SIGINT SIGTERM EXIT
		exit 1
	fi

	working_dir="$build_path/instance_$n"
	[ ! -d "$working_dir" ] && mkdir -p "$working_dir"

	pushd "$working_dir" &>/dev/null
	echo "starting instance $N in $(pwd)"

	# TODO: [Alex], 编译后当前脚本运行路径为:PX4-Autopilot/build/px4_sitl_default/build_gazebo
	# ../bin/px4 -i $N -d "$build_path/etc" -w sitl_${MODEL}_${N} -s etc/init.d-posix/rcS >out.log 2>err.log &
	../bin/px4 -i 0 -d "$build_path/etc" -w sitl_iris_0 -s etc/init.d-posix/rcS >out.log 2>err.log &
	echo ">>>>> [Alex: gazebo_sitl_multiple_run.sh] spawn_model(), sitl_${MODEL}_${N}"

	# python3 ${src_path}/Tools/sitl_gazebo/scripts/jinja_gen.py ${src_path}/Tools/sitl_gazebo/models/${MODEL}/${MODEL}.sdf.jinja ${src_path}/Tools/sitl_gazebo --mavlink_tcp_port $((4560+${N})) --mavlink_udp_port $((14560+${N})) --mavlink_id $((1+${N})) --gst_udp_port $((5600+${N})) --video_uri $((5600+${N})) --mavlink_cam_udp_port $((14530+${N})) --output-file /tmp/${MODEL}_${N}.sdf

	echo "Spawning ${MODEL}_${N} at ${X} ${Y}"

	# gz model --spawn-file=/tmp/${MODEL}_${N}.sdf --model-name=${MODEL}_${N} -x ${X} -y ${Y} -z 0.0
	gz model --spawn-file=${src_path}/Tools/sitl_gazebo/models/${MODEL_SDF}/${MODEL_SDF}.sdf --model-name=${MODEL_SDF} -x 0.0 -y 0.0 -z 0.0

	popd &>/dev/null

}

if [ "$1" == "-h" ] || [ "$1" == "--help" ]
then
	echo "Usage: $0 [-n <num_vehicles>] [-m <vehicle_model>] [-w <world>]"
	exit 1
fi

while getopts n:m:w:s:t:l: option
do
	case "${option}"
	in
		n) NUM_VEHICLES=${OPTARG};;
		m) VEHICLE_MODEL=${OPTARG};;
		w) WORLD=${OPTARG};;
		s) SCRIPT=${OPTARG};;
		t) TARGET=${OPTARG};;
		l) LABEL=_${OPTARG};;
	esac
done

num_vehicles=${NUM_VEHICLES:=3}
world=${WORLD:=empty}
target=${TARGET:=px4_sitl_default}
vehicle_model=${VEHICLE_MODEL:="iris"}
export PX4_SIM_MODEL=iris                                               # PX4仿真模型，这里固定为iris（这个用于rcS脚本）

echo ${SCRIPT}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
src_path="$SCRIPT_DIR/.."

echo ">>>>> [Alex: gazebo_sitl_multiple_run.sh], src_path=${src_path}"

build_path=${src_path}/build/${target}                                 # build_path=PX4-Autopilot/build/px4_sitl_default
mavlink_udp_port=14560
mavlink_tcp_port=4560

echo "killing running instances"
pkill -x px4 || true

sleep 1

source ${src_path}/Tools/setup_gazebo.bash ${src_path} ${src_path}/build/${target}

echo "Starting gazebo"
gzserver ${src_path}/Tools/sitl_gazebo/worlds/${world}.world --verbose &
sleep 5

n=0
# spawn_model iris $n 0.0 0.0 ${vehicle_model}

# TODO: [Alex], 创建目录PX4-Autopilot/build/instance_0
working_dir="$build_path/instance_$n"
[ ! -d "$working_dir" ] && mkdir -p "$working_dir"
pushd "$working_dir" &>/dev/null

# TODO: [Alex], 启动PX4，生成目录PX4-Autopilot/build/instance_0/sitl_iris_0
../bin/px4 -i 0 -d "$build_path/etc" -w sitl_iris_0 -s etc/init.d-posix/rcS >out.log 2>err.log &

# TODO: [Alex], 添加gazebo模型
gz model --spawn-file=${src_path}/Tools/sitl_gazebo/models/${vehicle_model}/${vehicle_model}.sdf --model-name=${vehicle_model} -x 0.0 -y 0.0 -z 0.0

popd &>/dev/null

trap "cleanup" SIGINT SIGTERM EXIT

echo "Starting gazebo client"
gzclient
