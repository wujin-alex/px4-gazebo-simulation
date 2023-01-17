# PX4-Gazebo-Simulation

本工程是基于PX4-Autopilot/Tools/sitl_gazebo修改而来，主要目的是将gazebo仿真部分的代码独立出来，但实际运行仍然需要PX4。

## 环境配置

### ROS2

- 安装gazebo相关功能包

```shell
$ sudo apt install ros-foxy-gazebo-*
```

- 安装mavlink

```shell
$ sudo apt-get install ros-foxy-mavlink
```

## 编译

```shell
$ cd sitl_gazebo
$ mkdir build && cd build
$ cmake ..
$ make
```

## 运行

### 编译PX4

启动仿真之前，需要先把PX4工程准备好并完成编译。

```shell
$ cd PX4-Autopilot
$ make px4_sitl_default gazebo
```

编译完后，修改`gazebo_sitl_single_run.sh`脚本内的px4_src_path变量对应的PX4工程目录。

### 启动

- 指定模型

  ```shell
  $ ./gazebo_sitl_single_run.sh -m alex_iris_realsense_d455
  ```

- 指定模型和世界

  ```shell
  $ ./gazebo_sitl_single_run.sh -m alex_iris_realsense_d455 -w baylands
  ```

- 设置模型初始位置
  
  ```shell
  $ ./gazebo_sitl_single_run.sh -m alex_iris_realsense_d455 -w baylands -x -0.2 -y 1.0
  ```
  
  