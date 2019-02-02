classdef Artist_Robot < Robot_Class
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Flag;% Flag to start/stop drawing process
    end
    
    methods
        function obj = Artist_Robot(dh,Num_Links,Limits,Base_Transform,Tool_Transform)
            obj@Robot_Class(dh,Num_Links,Limits,Base_Transform,Tool_Transform);% Call the constructor from the parent class Robot_Class
            obj.Flag = 0;
        end
        
        function File_Name=LoadImage(obj)
            %Delete any previously created file containing the positions to
            %draw by the Artist Robot.
            if exist('positions2draw.xlsx', 'file')
                delete('positions2draw.xlsx');
            end
            %The user select the JPG image from the hard disk, its
            %destination is concatinated with the file name.
            [fn, pn] = uigetfile('*.jpg','Select an image');
            File_Name_Destination = strcat(pn,fn);
            
            %Set the 3D matrix I to contain the image (in the form of pixel by
            I = imread(File_Name_Destination); %Read the image
            imshow(I); %Show the image in the assigned GUI axes
            
            File_Name=File_Name_Destination;
        end
        
        function ConvertImage(obj,Points,File_Name)
            
            I=imread(File_Name);%Read the image
            Igray= rgb2gray(I);% Convert the image to a black and white image
            [Width,~]=size(Igray);%Get the size of the image
            %Scale the image to match a 90*90 pixel size
            scale=90/Width;
            %This section processes the obtained (X,Y) points into
            %Robot_Class-compatible data
            ScaledPositions = scale*Points;%Scale the points
            NewX = (-1)*Points(:,1);% Invert the sign of the x values. We do this because of our external reference frame
            ScaledPositions=[scale*NewX,ScaledPositions(:,2)]/1000;% Create a matrix that contains the scaled x and y points
            
            % This next section of code, will go through the points and
            % reject any of them that are no more different from the last
            % value by 2mm.
            NewScaledPositions=ScaledPositions(1,:);% Grab the first row of points, these will always be taken in
            j=1;
            for i=2:numel(ScaledPositions)/2% Loop through all the points
                if norm(ScaledPositions(j,:)-ScaledPositions(i,:))>0.002 % if the distance between two consecutive points is less than 2mm, then we don't add it to the points to draw
                    NewScaledPositions = [NewScaledPositions;ScaledPositions(i,:)];% append the points to draw if they differ by a minimum of 2mm
                    j=i;
                end
            end

            hold on;
            Positions2Plot=1000*NewScaledPositions/scale;% Plot the points on the image using the inverse of the scale 
            NewOldX = (-1)*Positions2Plot(:,1);% Uninvert the X
            Positions2Plot = [NewOldX,Positions2Plot(:,2)];
            plot(Positions2Plot(:,1), Positions2Plot(:,2), 'bs', 'LineWidth', 2, 'MarkerSize', 5);% Plot the points on the image
            
            %Create an Excel File that contains the scaled (X,Y)positions
            filename = 'positions2draw.xlsx';
            data_cells=num2cell(NewScaledPositions);     %Convert data to cell array
            col_header={'X','Y'};     %Column cell array (for column labels)
            output_matrix=[col_header; data_cells];     %Join cell arrays
            xlswrite(filename,output_matrix);     %Write data and both headers
        end
        
        function Points=DrawImage(obj)
            %We convert our RGB matrix to a grayscale one in order to
            %obtain its 2D size
            hFH = imfreehand(); %Function used to draw the traces
            xy  = hFH.getPosition; %Store the X and Y pixel positions of the tarces in a cell array
            Response = questdlg('Would you like to save your traces?', ...
                'Confirmation', ...
                'SAVE AND FINISH', 'SAVE AND CONTINUE', 'UNDO', 'SAVE AND CONTINUE');
            if strcmpi(Response, 'UNDO')
                delete(hFH); % get rid of imfreehand remnant.
                xy=[];% If they wanted to undo the last trace, we should nullify the points gotten from imfreehand
                Points=[];% Nullify the variable to return as well
                obj.Flag = 0;% Keep the flag at zero so the GUI keeps asking
            elseif strcmpi(Response, 'SAVE AND CONTINUE')% if the response was to save and continue
                Points=xy;% Set the return variable to the ppoints gotten from imfreehand
                obj.Flag = 0;% The done flag should remain a zero
                hold on
                plot(xy(:,1), xy(:,2), 'ro', 'LineWidth', 2, 'MarkerSize', 1);% Plot those points on the image
                
            elseif strcmpi(Response, 'SAVE AND FINISH')% if the user is done tracing
                Points=xy;% Set the return variable to the ppoints gotten from imfreehand
                obj.Flag = 1;% Set the done flag to 1 so the GUI stops asking for traces
                hold on
                plot(xy(:,1), xy(:,2), 'ro', 'LineWidth', 2, 'MarkerSize', 1);% Plot those points on the image
            end
            delete(hFH);
            
        end
        
        function PenUp(obj)
            obj.MoveJoint(3,-pi/4);% Move the pen to -45 degrees up
        end
        
        function PenDown(obj)
            obj.MoveJoint(3,0);% Move the pen to 0 degrees. this puts the pen against the paper
        end
        
    end
end

