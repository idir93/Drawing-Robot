classdef Robot_Class < handle
    %Robot_Class
    %   This class has methids to create and store a robot, as well as
    %   functions to do forward and inverse kinematics and plotting.
    
    properties
        Linked_Robot% Variable that holds the linked robot
        Thetas%Variable that holds the Thetas for each joint in the robot
        Controller%Variable that holds the arduino configuration
        Servos%Variable that holds the servo configurations
        Num_Joints;%Variabel that holds the number of joints in the robot
        Num_Servos;%Variable that holds the number of servos in the robot.
        Hardware_Used%Variable that holds whether hardware is attached to the robot
        Tool_Position%Variable that holds the position of the tool in XYZ space
        Joint_Direction %Variable used to tell which direction is clockwise and counterclockwise for each joint. We put these into the arduino_map function we
                                          %created and use them as the max and min for the output. If we flip these,
                                          %it effectively flips the direction of rotation for the servo
    end
    
    methods
        function obj = Robot_Class(dh_parameters,Num_Links,Limits,Base,Tool)
             %INPUTS:
             %      dh_parameters: This is an array that specifies your DH
             %      parameters. It is the form of 
             %      [d1,a1,alpha1,offset1 (if used),d2,a2,alpha2,offset2
             %      (if used),...]
             
             %      Num_Links: This is the number of links that the robot
             %      has
             
             %      Limits: These are a vector that contain the limits for
             %      each joint. Will be in the form of
             %      [min1,max1,min2,max2,...]
             
             %      Base: A 4x4 transformation matrix that relates an
             %      external reference frame to the first joint of the
             %      robot. Or it can be a 1x3 vector that contains the
             %      translation if the external frame has the same
             %      orientation as the first joint.

             %      Tool: A 4x4 transformation matrix that relates an
             %      tool frame to the last joint of the
             %      robot. Or it can be a 1x3 vector that contains the
             %      translation if the tool frame has the same
             %      orientation as the last joint.
             %END INPUTS
            
             %OUTPUTS
             %      obj: This is the obj that is created when the
             %      constructor has finished. It will hold the robot as
             %      well as the angles associated with each joint
             %END OUTPUTS
         if(nargin==2)%If there were only 2 input arguments
             for(i=1:2*Num_Links)% Loop through twice as many joints because there is a lower and upper limit for each joint
                if(mod(i,2)==1)% If the joint number is odd, then it is a lower joint limit
                    Limits(i)=-90*pi/180;% Set it to -90 degrees
                else% Otherwise it is an even joint and it becomes the upper limit
                    Limits(i)=90*pi/180;% Set the limit to 90 degrees
                end
             end
             Base=[0,0,0];%The base transformation is defaulted to the same orientation as the first robot coordinate frame and has zero translation
             Tool=[0,0,0];%The tool transformation is defaulted to the same orientation as the last link with zero translational offset.
         end
         if(nargin==3)%If the Limits were defined but the base and tool transforms were not.
             Base=[0,0,0];%The base transformation is defaulted to the same orientation as the first robot coordinate frame and has zero translation
             Tool=[0,0,0];%The tool transformation is defaulted to the same orientation as the last link with zero translational offset.
         end
         if(nargin==4)%If the limits and the base were specified but not the tool
             Tool=[0,0,0];%The tool transformation is defaulted to the same orientation as the last link with zero translational offset.
         end
        
        if(mod(numel(dh_parameters),4) == 0) %Check to see if an offset was put into the dh parameters.           
            Used_Offset = 1; %If the number of elements in the dh parameters was evenly divisible by 4, then an offset was used and we should indicate this with a variable                                                       
        else                                                                                        
            Used_Offset = 0;%Otherwise an offset was not used.                                                        
        end                                                                                        
        
        if(Used_Offset == 1)% If an offset value os included into the parameters
               for(i=1:1:Num_Links)
                    % Grab the values that correspond to the dh parameters of the link
                    % The argument of the dh_parameters is used to shift to the new link
                    %after each iteration has completed
                    L(i)=Revolute('d',dh_parameters(4*i-3),'a',dh_parameters(4*i-2),'alpha',dh_parameters(4*i-1),'offset',dh_parameters(4*i),'modified','qlim',Limits(2*i-1:2*i));
                end
         else
                 for(i=1:1:Num_Links)
                    %Do the same thing as before excpet that no offset was included
                    L(i)=Revolute('d',dh_parameters(3*i-2),'a',dh_parameters(3*i-1),'alpha',dh_parameters(3*i),'modified','qlim',Limits(2*i-1:2*i));
                 end
        end
            
            obj.Linked_Robot = SerialLink(L,'base',Base,'tool',Tool,'name', 'robot');%Link the joints together and sets the name of the robot
            obj.Thetas=zeros(1,Num_Links);% Set the default state for the Thetas
            obj.Num_Joints=Num_Links;% Set the number of joints in the robot.
            obj.Num_Servos=0;% Set the default number of servos to zero since we haven't attached any yet
            obj.Servos=[];% Start off with a blank array for the servos
            T=obj.Linked_Robot.fkine(obj.Thetas);% Do a forward kinematics to set the current tool position 
            obj.Tool_Position=T.transl;% Set the current tool position to the previous forward kinematics
             obj.Joint_Direction= [1,0;1,0;1,0];  
            clear T;
        end
        
        function DisplayRobotParameters(obj)
             %INPUTS
            %       obj: This is automatically passed in when the function
            %       is called
            %END INPUTS
            disp("Number of Joints: ")% Display the number of joints in the robot
            disp(obj.Num_Joints);
            
            disp("Joint DH parameters:");% Display the dh parameters of the robot
            obj.Linked_Robot.display()
            
            disp(" ");
            disp("Current Theta Angles: ");% Display the current joint angles
            disp(obj.Thetas*180/pi)
            
            
            disp (" ");
            disp("Hardware Configuration:")% Difsplay the hardware configuration(Arduino Setup)
            disp(obj.Controller)
            
            disp(" ");
            disp("Servo Configuration:");% Display the configuration of the servos attached to the robot
            for(i=1:1:obj.Num_Servos)% Loop through all the servos and display them individually
            disp(obj.Servos(i));
            end
        end
        
        function PlotRobot(obj,View_Angles)
            %INPUTS
            %       obj: This is automatically passed in when the function
            %       is called
            
            %       View_Angles: This is the set of viewing angles that are
            %       used to set the view window for the plot. If this is
            %       not specified, it will overwrite the current axes but
            %       keep the same view
            %END INPUTS
            
            %Notes: This will overwrite the current plot, make sure that
            %you call the correct axes or figure before writing, otherwise
            %you will get an error.
            
            if(nargin==2)%If the number of arguments is 2, then the user wants to specify a viewing angle
                obj.Linked_Robot.plot(obj.Thetas,'view', View_Angles);
            else
                obj.Linked_Robot.plot(obj.Thetas);%Otherwise, they just wanted a regular plot/to update the existing plot
            end
        end
            
         function Transformation=FkineRobot(obj)%Function to do the forward kinematics on the robot
             %INPUTS
            %       obj: This is automatically passed in when the function
            %       is called
            %END INPUTS             
             Transformation=obj.Linked_Robot.fkine(obj.Thetas);%Return the transformation matrix from the fkine built within the robotics toolkit
             obj.Tool_Position=Transformation.transl;%Set the current tool position to the previous forward kinematics
         end
         
         function Angles=IkineRobot(obj,T,Mask,Initial_Angles)%Function to do the forward kinematics on the robot
             %INPUTS
            %       obj: This is automatically passed in when the function
            %       is called
            
            %       T: A 4x4 Transfomation matrix. Must be either a SE3
            %       object or a 4x4 homogeneous matrix
            %       Mask: This is used for when the robot has fewer than 6
            %       degrees of freedom. the mask for a 3 degree of freedom
            %       robot would look like [1,1,1,0,0,0]. A 2 degree of
            %       freedom robot will look like [1,1,0,0,0,0]
            
            %       Initial_Values: Vector that contains the initial
            %       guesses for the ikine. Must have the same length as the
            %       number of joints in the robot
            %END INPUTS
                %Angles=obj.Linked_Robot.ikunc(T,Initial_Values);%Return the transformation matrix from the fkine built within the robotics toolkit
                Minimized_Angles=obj.Linked_Robot.ikcon(T,Initial_Angles);
                Angles=obj.Linked_Robot.ikine(T,'mask',Mask,'q0',Minimized_Angles,'tol',1e-15);%Return the transformation matrix from the fkine built within the robotics toolkit
         end
         
         
         function Checked_Angle=CheckLimits(obj,Joint_Number,angle)%Function to check if the angle passed in or the Thetas in the robot class are valid
             %INPUTS:
             %      obj: the object, you don't need to worry about this as
             %      it is automatically passed in
             
             %      Joint_Number: The number of the joint that we want to
             %      compare the angle against.
             
             %      angle: The angle that we are checking against the joint
             %      limits for the given joint number
             %END INPUTS
             
             %OUTPUTS
             %      Checked_Angle: This is the value that has been checked
             %      against the joint limits. It can be anywhere between
             %      the limits of the specififed joint
             %END OUTPUTS
              if(angle > obj.Linked_Robot.qlim(Joint_Number,2))%If the angle passed in was bigger than the maximum for that joint
                   Checked_Angle = obj.Linked_Robot.qlim(Joint_Number,2);% Set the theta value to the maximum joint angle for that joint
                    msgbox("The value entered was too large and was set to the max positive value");
                    uiwait();
              elseif(angle < obj.Linked_Robot.qlim(Joint_Number,1))% If the angle passed in is less than the minimum joint angle for that joint
                   Checked_Angle = obj.Linked_Robot.qlim(Joint_Number,1);% Set the theta to the minimum joint angle for that joint
                    msgbox("The value entered was too small and was set to the max negative value")%Tell the user that the passed value exceeded the joint limit and was set to the joint limit
                    uiwait();
              else
              Checked_Angle=angle;%The angle passed in was not out of bounds, so just pass it back through
              end
         end
          
         function T=MoveRobot(obj,X,Y,Z)% Function to move the robot. If hardware is not used then it will just plot the robot on the GUI
             
             T=obj.FkineRobot();% Create the current transformation matrix
             T.t(1)=X; %Change the value in the X spot to the new one
             T.t(2)=Y; %Change the value in the Y spot to the new one
             T.t(3)=Z; %Change the value in the Z spot to the new one
             Joint_Angles = obj.IkineRobot(T,[1,1,1,0,0,0],obj.Thetas);%Perform the inverse kinematics on matrix from above with the initial guess of the current joint angles 
              for(i=1:1:obj.Num_Joints)%Loop through all the joints and move each one
                     obj.MoveJoint(i,Joint_Angles(i));% Move the joints to the locations found by the ikine function
              end
             obj.Tool_Position=T.transl;
         end
         
         function T= MoveJoint(obj,Joint_Number,Angle)
             %INPUTS
             %      obj: This is automatically passed in when the function
             %       is called
             
             %      Servo_Number: The number of the servo that you want to
             %      move. This is consistent with the joint number that you
             %      want to move
             
             %      angle: The angle that you want to move the servo. This
             %      value MUST be in RAD
             
             %      obj.Joint_Direction: This is the minimum angle that the servo will
             %      turn. It is used to switch the direction of travel for
             %      the servo
             
             %      obj.Joint_Direction: This is the maximum angle that the servo will
             %      turn. It is used in conjuction with the obj.Joint_Direction to
             %      switch the direction of travel. 
             %END INPUTS
             
             %NOTE: obj.Joint_Direction is either a 0 or a 1 and obj.Joint_Direction is the
             %opposite of this value. You need to figure out which set to
             %use to get the servo to turn in the direction you expect for
             %the given angle
             
             Checked_Angle=obj.CheckLimits(Joint_Number,Angle);%Check if the angle passed is in beyond the joint limit
             %We do this for all the conditions of hardware use or not, so
             %we just do it once and this makes the code easier to read.
             
             
             if(obj.Hardware_Used==1)
                Percentage=Arduino_Map(Checked_Angle,obj.Linked_Robot.qlim(Joint_Number,1),obj.Linked_Robot.qlim(Joint_Number,2),obj.Joint_Direction(Joint_Number,1),obj.Joint_Direction(Joint_Number,2));%Map the value from the angles to between 0 and 1
                writePosition(obj.Servos(Joint_Number),Percentage);%Write the percentage to the servo
                obj.Thetas(Joint_Number)=Checked_Angle;%Set the angles to the robot object that the GUI uses
                obj.PlotRobot();%Update the plots with the new thetas
                T=obj.FkineRobot();%Compute the end effector location with the current thetas that were just updated
             elseif(obj.Hardware_Used==2)%If hardware_Used is equal to 2, we are only using the hardware with no plotting of the gui
                Percentage=Arduino_Map(Checked_Angle,obj.Linked_Robot.qlim(Joint_Number,1),obj.Linked_Robot.qlim(Joint_Number,2),obj.Joint_Direction(Joint_Number,1),obj.Joint_Direction(Joint_Number,2));%Map the value from the angles to between 0 and 1
                writePosition(obj.Servos(Joint_Number),Percentage);%Write the percentage to the servo
             else%Otherwise, we are not using hardware at all and we are just using the GUI. 
                 obj.Thetas(Joint_Number)=Checked_Angle;%Set the GUI object thetas to the checked angle
                 obj.PlotRobot();%Update the robot plot with the new angles
                 T=obj.FkineRobot();%Compute the new end effector location
             end
         end
         
         function ConnectHardware(obj,ComPort,BoardType)%Function to connect the arduino to the robot
             %INPUTS
             %      obj: This is automatically passed in when the function
             %       is called
             
             %      ComPort: The port that the arduino should be on
             
             %      BoardType: The type of arduino used. ex. Uno,
             %      Mega2560,...
             %END INPUTS
             obj.Controller=arduino(ComPort,BoardType,'libraries','Servo');%Attempt to connect the arduino to matlab
             msgbox("Hardware Connected");%If the operation was successful, then display a message saying that
         end
        
         function AddServo(obj,Pin,Min_Pulse_Length,Max_Pulse_Length,Servo_Number,Replace)%Function to add a servo to the robot
             %INPUTS
             %      obj: This is automatically passed in when the function
             %       is called
             
             %      Pin: The pin that the servo is attached to. Must be in
             %      the form of 'D6', this is standard for what the arduino
             %      toolkit is expecting
             
             %      Min_Pulse_Length: The minimum pulse duration for the
             %      chosen servo. This is found with the datasheet
             
             %      Max_Pulse_Length: The maximum pulse duration for the
             %      chosen servo. This is found with the datasheet
             %END INPUTS
             if(strcmp(Servo_Number,'Last') && strcmp(Replace,'No'))% If the user wants to put the servo as the last joint and we are not replacing any joints
                 obj.Servos=[obj.Servos, servo(obj.Controller,Pin,'MaxPulseDuration',Max_Pulse_Length,'MinPulseDuration',Min_Pulse_Length)];%Create a servo and append it to the end
                 obj.Num_Servos=obj.Num_Servos+1;%Increment the number of servos
                 obj.MoveJoint(obj.Num_Servos,0);% Move the servo to the zero angle position
             elseif(~strcmp(Replace,'No'))% If we are replacing a servo
                    if(strcmp(Servo_Number,'Last'))%Check to see which place we are replacing, if its the last
                        Place=obj.Num_Servos;% Then place becomes the last element in the servos array
                    else
                        Place=str2double(Servo_Number);% or, we replace a servo based on the users choice
                    end
                    obj.Servos(Place)=servo(obj.Controller,Pin,'MaxPulseDuration',Max_Pulse_Length,'MinPulseDuration',Min_Pulse_Length);%Create a servo and place in it the spot the user wanted
                    obj.MoveJoint(Place,0);% Moe the joint to the zero angle
             elseif(~strcmp('Last',Servo_Number)&&strcmp(Replace,'No'))% If we are not replacing but the position is not the last, we are putting the joint somewhere in the middle
                    S=[];%Create a dummy variable to hold the servos
                    for(i=1:1:obj.Num_Servos)% Loop through the servos
                        if(i==str2double(Servo_Number))% Check to see if the current servo number matches the servo number the user passed in
                            S=[S,servo(obj.Controller,Pin,'MaxPulseDuration',Max_Pulse_Length,'MinPulseDuration',Min_Pulse_Length)];%If it does, then we will create a new servo and put it in the spot of i
                            obj.Num_Servos=obj.Num_Servos+1;%Increment the number of servos
                        end
                        S=[S,obj.Servos(i)];%Otherwise, we add the current servo configuration to the dummy variable
                        obj.MoveJoint(i,0);% Move the joint to the zero position
                    end
                    clear obj.Servos% Clear whats inside of the Servos variable and...
                    obj.Servos=S;% Replace it with the dummy variable
             else
                 %Do nothing
             end
         end
       
         function DetachHardware(obj)%Function to detach all hardware from the robot
            %INPUTS
            %       obj: This is automatically passed in when the function
            %       is called
            %END INPUTS
             obj.Controller=[]; %Clear the controller from the class
             obj.DetachServo(); % Detach the servos and since we didn't specify a number inside, we will clear all of them
             msgbox("All hardware has been detached from the robot");%Give a message box that tells the user that the hardware has been cleared
         end
         
         function DetachServo(obj,Servo_Number)% Function to detach servos on the robot
             S=[];%Creat a blank variable to store the new servos
             if(nargin == 1)%If no Servo number was given, we will delete all servos from the robot
                    clear Obj.Servos;
                    msgbox("All servos have been removed from the robot");%Tell the user that all the servos were deleted from the robot
             else%Otherwise a servo was specified
                 for(i=1:1:obj.Num_Servos)%Loop through all the servos and add them to the blank variable. We do this as long as the counter isn't at the servo number specified by the user
                     if(i ~= Servo_Number)%If the counter is not the same as the servo number specified
                        S=[S,obj.Servos(i)];%Add the current servo into the temporary variable
                     end
                 end
                 obj.Num_Servos = obj.Num_Servos - 1;%We have deleted a servo, so we should update the robot to reflect that
                 clear obj.Servos;%Clear the whole servos variable from the robot
                 Message=['Servo ' ,char(Servo_Number),' removed from hardware.'];%Give the user a message saying that the servo they wanted to delete was deleted
                 msgbox(Message);%Actually display that message
                 obj.Servos=S;%Set the servos variable in the robot to the temporary variable, this will effectively replace the servos variable with the servos that werent specified
                 clear S;%Clear the temporary variable
             end
         end
             
         function DeleteRobot(obj)%Function to delete the robot from memory
             obj.DetachHardware()%Call the function to detach all hardware
             clear obj.Num_Servos  %Clear all the variables associated with the robot
             clear obj.Num_Links 
             clear obj.Thetas 
             clear obj.Linked_Robot
             clear obj.Joint_Direction
             clear obj.Tool_Position
         end
    end
end

