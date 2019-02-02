classdef Webcam_Class < handle
    %WEBCAM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        cam;
        finalimg;
        Face_BB;
        Nose_BB;
        Mouth_BB;
        RightEye_BB;
        LeftEye_BB;
    end
    
    methods
        
        function OpenCam(obj)
            obj.cam = webcam();% get the webcam object properties
            obj.cam.Resolution='1280x720';% Change the resolution
            preview(obj.cam);% Create a figure that shows what the camera sees
        end
        
        function Capture(obj)
            webcamimg = snapshot(obj.cam);% Get  a image from the webcam
            imshow(webcamimg);% Show that image
            
            %Face detection
            Face_detect = vision.CascadeObjectDetector;% Method that detects faces in images
            obj.Face_BB=step(Face_detect,webcamimg);% Grab the bounding box that surrounds the face
            hold on
            for i = 1:size(obj.Face_BB,1)
                rectangle('Position',obj.Face_BB(i,:),'LineWidth',4,'LineStyle','-','EdgeColor','r');% Create a rectangle around the face that was detected
            end
            Face_Cropped = imcrop(webcamimg, obj.Face_BB);% Crop the image so only the face shows
            hold off
            imshow(Face_Cropped);% Show the cropped image
            
            %NOTE:
            % The next four sections will look for different features of
            % the face, and then will create and show a bounding box around
            % each feature
            
            
            %Right Eye Detection
            RightEye_Detect = vision.CascadeObjectDetector('RightEyeCART');
            obj.RightEye_BB=step(RightEye_Detect,Face_Cropped);
            hold on
            rectangle('Position',obj.RightEye_BB(1,:),'LineWidth',2,'LineStyle','-','EdgeColor','b');
            
            
            %Left Eye Detection
            LeftEye_Detect = vision.CascadeObjectDetector('LeftEyeCART');
            obj.LeftEye_BB=step(LeftEye_Detect,Face_Cropped);
            hold on
            rectangle('Position',obj.LeftEye_BB(1,:),'LineWidth',2,'LineStyle','-','EdgeColor','b');
            
            
            %Mouth Detection
            Mouth_Detect = vision.CascadeObjectDetector('Mouth','MergeThreshold',16);
            obj.Mouth_BB=step(Mouth_Detect,Face_Cropped);
            hold on
            rectangle('Position',obj.Mouth_BB(1,:),'LineWidth',2,'LineStyle','-','EdgeColor','r');
            
            
            %Nose Detection
            Nose_Detect = vision.CascadeObjectDetector('Nose','MergeThreshold',16);
            obj.Nose_BB=step(Nose_Detect,Face_Cropped);
            hold on
            rectangle('Position',obj.Nose_BB(1,:),'LineWidth',2,'LineStyle','-','EdgeColor','g');
            
            obj.finalimg= getimage();
        end
        
        function ConvertImage(obj,feature)
            
            finalinggray= rgb2gray(obj.finalimg);
            [Width,~]=size(finalinggray);
            %Scale the image to match a 90*90 cm^2 size
            scale=90/Width;
            %This section processes the obtained (X,Y) points into
            %Robot_Class-compatible data
            I = edge(finalinggray,'canny');
            hold off
            imshow(I);
            
            if feature == 0
                hold on
                rectangle('Position',obj.RightEye_BB(1,:),'LineWidth',2,'LineStyle','-','EdgeColor','b');
                RightEyeRawPoints = I(obj.RightEye_BB(1,2):obj.RightEye_BB(1,2) + obj.RightEye_BB(1,4), obj.RightEye_BB(1,1): obj.RightEye_BB(1,1)+ obj.RightEye_BB(1,3));
                for j =  obj.RightEye_BB(1,2):( obj.RightEye_BB(1,2) +  obj.RightEye_BB(1,4))% Loop through the rows
                    for i =  obj.RightEye_BB(1,1):( obj.RightEye_BB(1,1) +  obj.RightEye_BB(1,3))% Loop through the columns
                        append = [i,j];% Since we are scanning a binary map, we will get either a zero or 1
                        RightEyePoints = [ RightEyePoints ;  RightEyeRawPoints(k)*append];% Multiply each pixel of the image by the binary map, if the b inary map value was a zero, we wont add that value because it isn't a trace
                        k=k+1;% Increment k
                    end
                end
                RightEyePoints =  RightEyePoints(any( RightEyePoints,2),:);% Clear all the zeros from the matrix
                Points=RightEyePoints;% Points to draw become the scanned points

 
                
%                 RightEyePoints = [];
%                 m=[0,1 ; 1,1 ; 1,0 ; 1,-1 ; 0,-1 ; -1,-1 ; -1,0 ; -1,1];
%                 T=zeros(1,8);
%                 
%                 for i =  obj.RightEye_BB(1,2):1:( obj.RightEye_BB(1,2) +  obj.RightEye_BB(1,4))
%                     for j =  obj.RightEye_BB(1,1):( obj.RightEye_BB(1,1) +  obj.RightEye_BB(1,3))
%                          x_scan=i;
%                          y_scan=j;
%                         if(RightEyeRawPoints(i,j))
%                             RightEyePoints=[RightEyePoints;i,j];
%                             for(k=1:1:8)
%                                 if(RightEyeRawPoints(i,j)+m(k,:))
%                                      T(k)=1;
%                                 else
%                                     T(k)=0;
%                                 end
%                             end
%                              
%                          end
%                             i=x_scan;
%                             j=y_scan;
%                         end
%                     end
       
                    %NOTE: the next 3 sections work the same as the right
                    %eye, except that we are scanning a different feature
                
            elseif feature == 1
                hold on
                rectangle('Position',obj.LeftEye_BB(1,:),'LineWidth',2,'LineStyle','-','EdgeColor','b');
                LeftEyeRawPoints = I(obj.LeftEye_BB(1,2):obj.LeftEye_BB(1,2) + obj.LeftEye_BB(1,4), obj.LeftEye_BB(1,1): obj.LeftEye_BB(1,1)+ obj.LeftEye_BB(1,3));
                k=1;
                LeftEyePoints = [];
                for j =  obj.LeftEye_BB(1,2):( obj.LeftEye_BB(1,2) +  obj.LeftEye_BB(1,4))
                    
                    for i =  obj.LeftEye_BB(1,1):( obj.LeftEye_BB(1,1) +  obj.LeftEye_BB(1,3))
                        append = [i,j];
                        LeftEyePoints = [ LeftEyePoints ;  LeftEyeRawPoints(k)*append];
                        k=k+1;
                    end
                end
                LeftEyePoints =  LeftEyePoints(any( LeftEyePoints,2),:);
                Points=LeftEyePoints;
                
            elseif feature == 2
                hold on
                rectangle('Position',obj.Mouth_BB(1,:),'LineWidth',2,'LineStyle','-','EdgeColor','r');
                MouthRawPoints = I(obj.Mouth_BB(1,2):obj.Mouth_BB(1,2) + obj.Mouth_BB(1,4),obj.Mouth_BB(1,1): obj.Mouth_BB(1,1)+ obj.Mouth_BB(1,3));
                k=1;
                MouthPoints = [];
                for j =  obj.Mouth_BB(1,2):( obj.Mouth_BB(1,2) +  obj.Mouth_BB(1,4))
                    
                    for i =  obj.Mouth_BB(1,1):( obj.Mouth_BB(1,1) +  obj.Mouth_BB(1,3))
                        append = [i,j];
                        MouthPoints = [ MouthPoints ;  MouthRawPoints(k)*append];
                        k=k+1;
                    end
                end
                MouthPoints =  MouthPoints(any( MouthPoints,2),:);
                Points= MouthPoints;
                
            else
                hold on
                rectangle('Position',obj.Nose_BB(1,:),'LineWidth',2,'LineStyle','-','EdgeColor','g');
                NoseRawPoints =  I(obj.Nose_BB(1,2):obj.Nose_BB(1,2) + obj.Nose_BB(1,4), obj.Nose_BB(1,1): obj.Nose_BB(1,1)+ obj.Nose_BB(1,3));
                k=1;
                NosePoints = [];
                for j =  obj.Nose_BB(1,2):( obj.Nose_BB(1,2) +  obj.Nose_BB(1,4))
                    for i =  obj.Nose_BB(1,1):( obj.Nose_BB(1,1) + obj. Nose_BB(1,3))
                        append = [i,j];
                        NosePoints = [ NosePoints ;  NoseRawPoints(k)*append];
                        k=k+1;
                    end
                end
                
                NosePoints =  NosePoints(any( NosePoints,2),:);
                Points=NosePoints;
            end
            
            %Note: Here we are going to use the same algorithm for
            %conveting the traces to points from the artist robot class
            
            
            %Delete any previously created file containing the positions to
            %draw by the Artist Robot.
            if exist('positions2draw.xlsx', 'file')
                delete('positions2draw.xlsx');
            end
            [Width,~]=size(I);
            %Scale the image to match a 90*90 cm^2 size
            scale=90/Width;
            %This section processes the obtained (X,Y) points into
            %Robot_Class-compatible data
            ScaledPositions = scale*Points;
            NewX = (-1)*Points(:,1);
            ScaledPositions=[scale*NewX,ScaledPositions(:,2)]/1000;
            NewScaledPositions=ScaledPositions(1,:);
            j=1;
            
            for i=2:numel(ScaledPositions)/2
                if norm(ScaledPositions(j,:)-ScaledPositions(i,:))>0.002
                    NewScaledPositions = [NewScaledPositions;ScaledPositions(i,:)];
                    j=i;
                end
            end
            
            j=1;
            NewNewScaledPositions=NewScaledPositions(1,:);
            for i=2:numel(NewScaledPositions)/2
                if norm(NewScaledPositions(j,:)-NewScaledPositions(i,:))>0.015
                    NewNewScaledPositions = [NewNewScaledPositions; 10000 10000; NewScaledPositions(i,:)];
                    j=i;
                else
                    NewNewScaledPositions=[NewNewScaledPositions; NewScaledPositions(i,:)];
                end
            end
            
            %Create an Excel File that contains the scaled (X,Y)positions
            filename = 'positions2draw.xlsx';
            data_cells=num2cell(NewNewScaledPositions);     %Convert data to cell array
            col_header={'X','Y'};     %Column cell array (for column labels)
            output_matrix=[col_header; data_cells];     %Join cell arrays
            xlswrite(filename,output_matrix);     %Write data and both headers
            
        end
        
    end
end
