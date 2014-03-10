#!/bin/bash

# this way the script can be called from any directory
SCRIPT_ROOT=$(dirname $(readlink --canonicalize --no-newline $BASH_SOURCE))
cd $SCRIPT_ROOT
cd ../urdf

if [ $# -gt 0 ] ; then
    if [ "$1" = '--all' ]; then
        if [ -d config ]; then

            rm -rf ~/.gazebo/models/coman_urdf

            echo "Regenerating database.config for coman_gazebo"

cat > ../../coman_gazebo/database/database.config << EOF
<?xml version='1.0'?>
<database>
<name>Coman Gazebo Database</name>
<license>Creative Commons Attribution 3.0 Unported</license>
<models>
EOF

            for i in config/*.urdf.xacro; do
                cd $SCRIPT_ROOT
                cd ../urdf
                if [ -r $i ]; then

                    echo "Processing file $i"
                    model_name="`python ../script/get_model_params.py ${i} model_name`"
                    model_version="`python ../script/get_model_params.py ${i} model_version`"
                    model_filename=$(basename -s ".urdf.xacro" $i)
                    echo "${model_filename} configures model ${model_name}, version ${model_version}"

                    cp $i coman_config.urdf.xacro
                    mkdir -p ../../coman_gazebo/database/$model_filename
                    echo "<uri>file://${model_filename}</uri>" >> ../../coman_gazebo/database/database.config

rm -f ../../coman_gazebo/database/$model_filename/model.config                    
cat >> ../../coman_gazebo/database/$model_filename/model.config << EOF
<?xml version="1.0"?>
<model>
  <name>$model_name</name>
  <version>$model_version</version>
  <sdf version='1.4'>coman.sdf</sdf>

  <author>
   <name>Enrico Mingo</name>
   <email>enrico.mingo@iit.it</email>
  </author>

  <description>
    Simulation of the COMAN Humanoid Robot from IIT.
  </description>
</model>
EOF
                    
                    cp ../../coman_gazebo/database/$model_filename/model.config ../../coman_gazebo/database/$model_filename/manifest.xml
                    cp ../../coman_gazebo/database/$model_filename/model.config ../../coman_gazebo/database/$model_filename/${model_filename}.config


                    echo "Creating bare urdf of coman.urdf.xacro ..."
                    rosrun xacro xacro.py coman.urdf.xacro > ${model_filename}.urdf
                    echo "...${model_filename}.urdf correctly created!"

                    echo "Creating sdf of coman_robot.urdf.xacro"
                    rosrun xacro xacro.py coman_robot.urdf.xacro > coman_robot.urdf
                    gzsdf print coman_robot.urdf > coman.sdf
                    python ../script/gazebowtf.py coman.gazebo.wtf coman_config.urdf.xacro > coman2.sdf
                    mv coman2.sdf coman.sdf
                    rm coman_robot.urdf
                    echo "...sdf correctly created!"

                    echo "Installing robot model in coman_gazebo/${model_filename}"
                    mv coman.sdf ../../coman_gazebo/database/${model_filename}/

                    echo "Creating srdf from coman.srdf.xacro"
                    cd ../../coman_srdf/srdf
                    rosrun xacro xacro.py coman.srdf.xacro > ${model_filename}.srdf 
                    echo "...created ${model_filename}.srdf!"
                    
                    echo 
                    echo 
                    echo "Complete! Enjoy ${model_name} ver ${model_version} in GAZEBO!"
                    echo "If the model requires it, remember to check ../../coman_gazebo/${model_filename}/conf/"
                    echo
                    echo
                fi
            done

            cd $SCRIPT_ROOT
            cd ../urdf
            
            echo "</models>" >> ../../coman_gazebo/database/database.config
            echo "</database>" >> ../../coman_gazebo/database/database.config
            
            unset i
            
            rm coman_config.urdf.xacro
            cp -r ../meshes/ ../../coman_gazebo/database/coman/
        fi
    fi
else

    cp config/coman.urdf.xacro coman_config.urdf.xacro

    echo "Creating bare urdf of coman.urdf.xacro"
    rosrun xacro xacro.py coman.urdf.xacro > coman.urdf
    echo "...urdf correctly created!"

    echo "Creating urdf of coman_robot.urdf.xacro"
    rosrun xacro xacro.py coman_robot.urdf.xacro > coman_robot.urdf
    echo "...urdf correctly created!"

    echo "Creating sdf of coman_robot.urdf..."
    gzsdf print coman_robot.urdf > coman.sdf

    python ../script/gazebowtf.py coman.gazebo.wtf coman_config.urdf.xacro > coman2.sdf

    mv coman2.sdf coman.sdf

    echo "...sdf correctly created!"

    echo "Removing coman_robot.urdf."
    rm coman_robot.urdf


    echo "Moving coman.sdf in coman_gazebo/sdf."
    mv coman.sdf ../../coman_gazebo/sdf/

    echo "Copying meshes in coman_gazebo/sdf."
    cp -r ../meshes/ ../../coman_gazebo/sdf/

    cd ../../coman_gazebo

    echo "Copying all data in coman_gazebo/sdf in ~/.gazebo/models/coman_urdf"

    rm -rf ~/.gazebo/models/coman_urdf
    rm -rf ~/.gazebo/models/coman
    cp -r sdf ~/.gazebo/models/coman

    echo "Creating srdf from coman.srdf.xacro"
    cd ../coman_srdf/srdf
    rosrun xacro xacro.py coman.srdf.xacro > coman.srdf 
    echo "...created coman.srdf!"

    cd $SCRIPT_ROOT
    cd ../urdf
    rm coman_config.urdf.xacro
     
    echo "Finish! Enjoy COMAN in GAZEBO!"

fi

cd $SCRIPT_ROOT
cd ../urdf
cp config/coman.urdf.xacro coman_config.urdf.xacro
