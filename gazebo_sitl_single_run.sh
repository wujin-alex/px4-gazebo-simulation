#!/bin/bash
# run multiple instances of the 'px4' binary, with the gazebo SITL simulation
# It assumes px4 is already built, with 'make px4_sitl_default gazebo'
# PX4仿真器默认发送的TCP端口为4560
# gazebo运行单机示例：
# ./gazebo_sitl_single_run.sh -m alex_iris_realsense_d435
# ./gazebo_sitl_single_run.sh -m alex_iris_realsense_d435 -w baylands
# ./gazebo_sitl_single_run.sh -m alex_iris_realsense_d435 -w baylands -x -2.0 y 2.0

function cleanup() {
	pkill -x px4
	pkill gzclient
	pkill gzserver
}

if [ "$1" == "-h" ] || [ "$1" == "--help" ]
then
	echo "Usage: $0 [-m <vehicle_model>] [-w <world>] [-x <init_x>] [-y <init_y>]"
	exit 1
fi

while getopts m:w:d:x:y:s:t: option
do
	case "${option}"
	in
		m) VEHICLE_MODEL=${OPTARG};;
		w) WORLD=${OPTARG};;
		d) DIR_WORLD=${OPTARG};;
		x) PX=${OPTARG};;
		y) PY=${OPTARG};;
		s) SCRIPT=${OPTARG};;
		t) TARGET=${OPTARG};;
	esac
done

vehicle_model=${VEHICLE_MODEL:="iris"}
world=${WORLD:=empty}
dir_world=${DIR_WORLD:=""}
px=${PX:=0.0}
py=${PY:=0.0}
target=${TARGET:=px4_sitl_default}

export PX4_SIM_MODEL=iris                                               # PX4仿真模型，这里固定为iris（这个用于rcS脚本）

echo ${SCRIPT}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
src_path="$SCRIPT_DIR"
echo ">>>>> [Alex: gazebo_sitl_multiple_run.sh], src_path=${src_path}"

# TODO: [Alex], 根据PX4工程路径设置
px4_src_path="/home/alex/Desktop/PX4-Autopilot_v1.12.3_learning"       # 设置PX4工程目录
px4_build_path=${px4_src_path}/build/${target}                         # PX4编译路径，build_path=PX4-Autopilot/build/px4_sitl_default
# build_path=${src_path}/build/${target}                               # build_path=PX4-Autopilot/build/px4_sitl_default
mavlink_udp_port=14560
mavlink_tcp_port=4560

echo "killing running instances"
pkill -x px4 || true

sleep 1

source ${src_path}/setup_gazebo.bash ${src_path} ${src_path}/sitl_gazebo/build

echo "Starting gazebo"
gzserver ${src_path}/sitl_gazebo/worlds/${world}.world --verbose &
sleep 5

n=0

# TODO: [Alex], 创建目录PX4-Autopilot/build/instance_0
working_dir="$px4_build_path/instance_$n"
[ ! -d "$working_dir" ] && mkdir -p "$working_dir"
pushd "$working_dir" &>/dev/null

# TODO: [Alex], 启动PX4，生成目录PX4-Autopilot/build/instance_0/sitl_iris_0
../bin/px4 -i 0 -d "$px4_build_path/etc" -w sitl_iris_0 -s etc/init.d-posix/rcS >out.log 2>err.log &

# TODO: [Alex], 添加gazebo模型
gz model --spawn-file=${src_path}/sitl_gazebo/models/${vehicle_model}/${vehicle_model}.sdf --model-name=${vehicle_model} -x ${px} -y ${py} -z 0.0

popd &>/dev/null

trap "cleanup" SIGINT SIGTERM EXIT

echo "Starting gazebo client"
gzclient
