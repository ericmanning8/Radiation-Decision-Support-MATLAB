function slider_callback(h, eventdata):
    axes(handles.Img);
    imshow(dicom_images(:,:,currentSlice));
end