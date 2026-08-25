
const std = @import("std");
const SDL = @cImport({@cInclude("SDL3/SDL.h");});
pub const Image = @import("Image.zig");
pub const Color = @import("Color.zig");
pub const Matrix = @import("Matrix.zig");
pub const Quaternion = @import("Quaternion.zig");
pub const vectors = @import("vectors.zig");
pub const Vec2T = vectors.Vec2T;
pub const Vec3T = vectors.Vec3T;

const EXIT_SUCCESS: u8 = 0;
const EXIT_FAILURE: u8 = 1;

pub const Vertex = struct {
  pos: Vec3T(f32),
  color: Color,
  uv: Vec2T(f32)
};

pub const window = struct {
  
  const global = struct {
    var window: ?*SDL.SDL_Window = null;
    var device: ?*SDL.SDL_GPUDevice = null;
    var sampler: ?*SDL.SDL_GPUSampler = null;
    var depth_texture: ?*SDL.SDL_GPUTexture = null;
    var graphics_pipeline: ?*SDL.SDL_GPUGraphicsPipeline = null;
    var dimensions: Vec2T(i32) = .{ .x = 0, .y = 0 };
  };
  
  const frame = struct {
    var render_pass: ?*SDL.SDL_GPURenderPass = null;
    var swapchain_texture: ?*SDL.SDL_GPUTexture = null;
    var command_buffer: ?*SDL.SDL_GPUCommandBuffer = null;
  };
  
  pub fn create(title: []const u8, width: i32, height: i32) void {
    if (!SDL.SDL_Init(SDL.SDL_INIT_VIDEO)) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    std.debug.assert(width > 0);
    std.debug.assert(height > 0);
    
    const min: i32 = 128;
    global.dimensions = .{
      .x = @max(width, min),
      .y = @max(height, min),
    };
    
    std.debug.assert(global.window == null);
    std.debug.assert(global.device == null);
    
    global.window = SDL.SDL_CreateWindow(@ptrCast(title), global.dimensions.x, global.dimensions.y, SDL.SDL_WINDOW_RESIZABLE);
    if (global.window == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    global.device = SDL.SDL_CreateGPUDevice(SDL.SDL_GPU_SHADERFORMAT_SPIRV, true, null);
    if (global.device == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    if (!SDL.SDL_ClaimWindowForGPUDevice(global.device, global.window)) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    if (!SDL.SDL_SetGPUSwapchainParameters(global.device, global.window, SDL.SDL_GPU_SWAPCHAINCOMPOSITION_SDR, SDL.SDL_GPU_PRESENTMODE_VSYNC)) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    if (!SDL.SDL_SetWindowMinimumSize(global.window, min, min)) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    const vertex_code: []const u8 = @embedFile("../shaders/vertex.spv");
    const fragment_code: []const u8 = @embedFile("../shaders/fragment.spv");
    
    var vertex_shader_create_info: SDL.SDL_GPUShaderCreateInfo = .{
      .code = @ptrCast(vertex_code),
      .code_size = vertex_code.len,
      .entrypoint = "main",
      .format = SDL.SDL_GPU_SHADERFORMAT_SPIRV,
      .stage = SDL.SDL_GPU_SHADERSTAGE_VERTEX,
      .num_uniform_buffers = 1,
    };
    
    var fragment_shader_create_info: SDL.SDL_GPUShaderCreateInfo = .{
      .code = @ptrCast(fragment_code),
      .code_size = fragment_code.len,
      .entrypoint = "main",
      .format = SDL.SDL_GPU_SHADERFORMAT_SPIRV,
      .stage = SDL.SDL_GPU_SHADERSTAGE_FRAGMENT,
      .num_samplers = 1,
    };
    
    const vertex_shader_program: ?*SDL.SDL_GPUShader = SDL.SDL_CreateGPUShader(global.device, &vertex_shader_create_info);
    if (vertex_shader_program == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    const fragment_shader_program: ?*SDL.SDL_GPUShader = SDL.SDL_CreateGPUShader(global.device, &fragment_shader_create_info);
    if (fragment_shader_program == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    defer SDL.SDL_ReleaseGPUShader(global.device, vertex_shader_program);
    defer SDL.SDL_ReleaseGPUShader(global.device, fragment_shader_program);
    
    const position_attribute: SDL.SDL_GPUVertexAttribute = .{
      .buffer_slot = 0,
      .location = 0,
      .format = SDL.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3,
      .offset = @offsetOf(Vertex, "pos"),
    };
    
    const color_attribute: SDL.SDL_GPUVertexAttribute = .{
      .buffer_slot = 0,
      .location = 1,
      .format = SDL.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4,
      .offset = @offsetOf(Vertex, "color"),
    };
    
    const texcoords_attribute: SDL.SDL_GPUVertexAttribute = .{
      .buffer_slot = 0,
      .location = 2,
      .format = SDL.SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2,
      .offset = @offsetOf(Vertex, "uv"),
    };
    
    var vertex_attributes: [3]SDL.SDL_GPUVertexAttribute = .{
      position_attribute,
      color_attribute,
      texcoords_attribute,
    };
    
    var vertex_buffer_description: SDL.SDL_GPUVertexBufferDescription = .{
      .input_rate = SDL.SDL_GPU_VERTEXINPUTRATE_VERTEX,
      .pitch = @sizeOf(Vertex),
    };
    
    var color_target_description: SDL.SDL_GPUColorTargetDescription = .{
      .format = SDL.SDL_GetGPUSwapchainTextureFormat(global.device, global.window),
      .blend_state = .{
        .enable_blend = true,
        .color_blend_op = SDL.SDL_GPU_BLENDOP_ADD,
        .alpha_blend_op = SDL.SDL_GPU_BLENDOP_ADD,
        .src_color_blendfactor = SDL.SDL_GPU_BLENDFACTOR_SRC_ALPHA,
        .dst_color_blendfactor = SDL.SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
        .src_alpha_blendfactor = SDL.SDL_GPU_BLENDFACTOR_SRC_ALPHA,
        .dst_alpha_blendfactor = SDL.SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA,
      },
    };
    
    const sampler_create_info: SDL.SDL_GPUSamplerCreateInfo = .{
      .min_filter = SDL.SDL_GPU_FILTER_NEAREST,
      .mag_filter = SDL.SDL_GPU_FILTER_NEAREST,
      .mipmap_mode = SDL.SDL_GPU_SAMPLERMIPMAPMODE_NEAREST,
      .address_mode_u = SDL.SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
      .address_mode_v = SDL.SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
      .address_mode_w = SDL.SDL_GPU_SAMPLERADDRESSMODE_REPEAT,
    };
    
    const depth_texture_create_info: SDL.SDL_GPUTextureCreateInfo = .{
      .type = SDL.SDL_GPU_TEXTURETYPE_2D,
      .format = SDL.SDL_GPU_TEXTUREFORMAT_D16_UNORM,
      .usage = SDL.SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET,
      .width = @intCast(global.dimensions.x),
      .height = @intCast(global.dimensions.y),
      .layer_count_or_depth = 1,
      .num_levels = 1,
      .sample_count = SDL.SDL_GPU_SAMPLECOUNT_1
    };
    
    const graphics_pipeline_create_info: SDL.SDL_GPUGraphicsPipelineCreateInfo = .{
      .vertex_input_state = .{
        .num_vertex_buffers = 1,
        .vertex_buffer_descriptions = &vertex_buffer_description,
        .num_vertex_attributes = vertex_attributes.len,
        .vertex_attributes = &vertex_attributes,
      },
      .target_info = .{
        .num_color_targets = 1,
        .color_target_descriptions = &color_target_description,
        .has_depth_stencil_target = true,
        .depth_stencil_format = SDL.SDL_GPU_TEXTUREFORMAT_D16_UNORM,
      },
      .depth_stencil_state = .{
        .enable_depth_test = true,
        .enable_depth_write = true,
        .compare_op = SDL.SDL_GPU_COMPAREOP_LESS_OR_EQUAL,
      },
      .vertex_shader = vertex_shader_program,
      .fragment_shader = fragment_shader_program,
      .primitive_type = SDL.SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
    };
    
    std.debug.assert(global.sampler == null);
    std.debug.assert(global.depth_texture == null);
    std.debug.assert(global.graphics_pipeline == null);
    
    global.depth_texture = SDL.SDL_CreateGPUTexture(global.device, &depth_texture_create_info);
    if (global.depth_texture == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    global.sampler = SDL.SDL_CreateGPUSampler(global.device, &sampler_create_info);
    if (global.sampler == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    global.graphics_pipeline = SDL.SDL_CreateGPUGraphicsPipeline(global.device, &graphics_pipeline_create_info);
    if (global.graphics_pipeline == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
  }
  
  pub fn destroy() void {
    std.debug.assert(global.device != null);
    std.debug.assert(global.window != null);
    std.debug.assert(global.sampler != null);
    std.debug.assert(global.depth_texture != null);
    std.debug.assert(global.graphics_pipeline != null);
    
    SDL.SDL_ReleaseGPUSampler(global.device, global.sampler);
    SDL.SDL_ReleaseGPUTexture(global.device, global.depth_texture);
    SDL.SDL_ReleaseGPUGraphicsPipeline(global.device, global.graphics_pipeline);
    SDL.SDL_DestroyGPUDevice(global.device);
    SDL.SDL_DestroyWindow(global.window);
    SDL.SDL_Quit();
    
    global.window = null;
    global.device = null;
    global.sampler = null;
    global.depth_texture = null;
    global.graphics_pipeline = null;
    global.dimensions = .{ .x = 0, .y = 0 };
  }
  
  pub fn isOpen() bool {
    var event: SDL.SDL_Event = undefined;
    while (SDL.SDL_PollEvent(&event)) {
      if (event.type == SDL.SDL_EVENT_WINDOW_CLOSE_REQUESTED) {
        return false;
      }
    } return true;
  }
  
  pub fn clear(clear_color: Color) void {
    std.debug.assert(global.window != null);
    std.debug.assert(global.device != null);
    
    std.debug.assert(frame.render_pass == null);
    std.debug.assert(frame.command_buffer == null);
    std.debug.assert(frame.swapchain_texture == null);
    
    frame.command_buffer = SDL.SDL_AcquireGPUCommandBuffer(global.device);
    if (frame.command_buffer == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    var width: u32 = undefined;
    var height: u32 = undefined;
    if (!SDL.SDL_WaitAndAcquireGPUSwapchainTexture(frame.command_buffer, global.window, &frame.swapchain_texture, &width, &height)) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    std.debug.assert(width < std.math.maxInt(i32));
    std.debug.assert(height < std.math.maxInt(i32));
    
    const prev_dimensions: Vec2T(i32) = .{
      .x = global.dimensions.x,
      .y = global.dimensions.y,
    };
    
    global.dimensions = .{
      .x = @intCast(width),
      .y = @intCast(height),
    };
    
    if ((prev_dimensions.x != global.dimensions.x) or (prev_dimensions.y != global.dimensions.y)) {
      std.debug.assert(global.depth_texture != null);
      SDL.SDL_ReleaseGPUTexture(global.device, global.depth_texture);
      global.depth_texture = null;
      
      const depth_texture_create_info: SDL.SDL_GPUTextureCreateInfo = .{
        .type = SDL.SDL_GPU_TEXTURETYPE_2D,
        .format = SDL.SDL_GPU_TEXTUREFORMAT_D16_UNORM,
        .usage = SDL.SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET,
        .width = @intCast(global.dimensions.x),
        .height = @intCast(global.dimensions.y),
        .layer_count_or_depth = 1,
        .num_levels = 1,
        .sample_count = SDL.SDL_GPU_SAMPLECOUNT_1
      };
      
      global.depth_texture = SDL.SDL_CreateGPUTexture(global.device, &depth_texture_create_info);
      if (global.depth_texture == null) {
        std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
        std.process.exit(EXIT_FAILURE);
      }
    }
    
    const color_target_info: SDL.SDL_GPUColorTargetInfo = .{
      .clear_color = .{
        .r = clear_color.r,
        .g = clear_color.g,
        .b = clear_color.b,
        .a = clear_color.a,
      },
      .load_op = SDL.SDL_GPU_LOADOP_CLEAR,
      .store_op = SDL.SDL_GPU_STOREOP_STORE,
      .texture = frame.swapchain_texture,
    };
    
    const depth_stencil_target_info: SDL.SDL_GPUDepthStencilTargetInfo = .{
      .texture = global.depth_texture,
      .clear_depth = 1,
      .load_op = SDL.SDL_GPU_LOADOP_CLEAR,
      .store_op = SDL.SDL_GPU_STOREOP_DONT_CARE,      
      .stencil_load_op = SDL.SDL_GPU_LOADOP_DONT_CARE,
      .stencil_store_op = SDL.SDL_GPU_STOREOP_DONT_CARE,
      .cycle = true
    };
    
    frame.render_pass = SDL.SDL_BeginGPURenderPass(frame.command_buffer, &color_target_info, 1, &depth_stencil_target_info);
    if (frame.render_pass == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    std.debug.assert(global.graphics_pipeline != null);
    SDL.SDL_BindGPUGraphicsPipeline(frame.render_pass, global.graphics_pipeline);
  }
  
  pub fn display() void {
    std.debug.assert(frame.render_pass != null);
    std.debug.assert(frame.command_buffer != null);
    std.debug.assert(frame.swapchain_texture != null);
    
    SDL.SDL_EndGPURenderPass(frame.render_pass);
    if (!SDL.SDL_SubmitGPUCommandBuffer(frame.command_buffer)) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    frame.render_pass = null;
    frame.command_buffer = null;
    frame.swapchain_texture = null;
  }
  
  pub fn vsync(toggle: bool) void {
    std.debug.assert(global.window != null);
    std.debug.assert(global.device != null);
    
    if (toggle) {
      if (!SDL.SDL_SetGPUSwapchainParameters(global.device, global.window, SDL.SDL_GPU_SWAPCHAINCOMPOSITION_SDR, SDL.SDL_GPU_PRESENTMODE_VSYNC)) {
        std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
        std.process.exit(EXIT_FAILURE);
      } return;
    }
    
    if (SDL.SDL_WindowSupportsGPUPresentMode(global.device, global.window, SDL.SDL_GPU_PRESENTMODE_IMMEDIATE)) {
      if (!SDL.SDL_SetGPUSwapchainParameters(global.device, global.window, SDL.SDL_GPU_SWAPCHAINCOMPOSITION_SDR, SDL.SDL_GPU_PRESENTMODE_IMMEDIATE)) {
        std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
        std.process.exit(EXIT_FAILURE);
      } return;
    }
    
    if (SDL.SDL_WindowSupportsGPUPresentMode(global.device, global.window, SDL.SDL_GPU_PRESENTMODE_MAILBOX)) {
      if (!SDL.SDL_SetGPUSwapchainParameters(global.device, global.window, SDL.SDL_GPU_SWAPCHAINCOMPOSITION_SDR, SDL.SDL_GPU_PRESENTMODE_MAILBOX)) {
        std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
        std.process.exit(EXIT_FAILURE);
      } return;
    }
    
    if (!SDL.SDL_SetGPUSwapchainParameters(global.device, global.window, SDL.SDL_GPU_SWAPCHAINCOMPOSITION_SDR, SDL.SDL_GPU_PRESENTMODE_VSYNC)) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
  }
};

pub const Mesh = struct {
  
  const Private = struct {
    quaternion: Quaternion,
    num_vertices: usize,
    vertex_buffer: ?*SDL.SDL_GPUBuffer,
    gpu_texture: ?*SDL.SDL_GPUTexture,
  }; private: Private,
  
  scale: f64,
  position: Vec3T(f64),
  
  pub fn create() Mesh {
    var this: Mesh = .{
      .private = .{
        .quaternion = .unit(),
        .num_vertices = 0,
        .vertex_buffer = null,
        .gpu_texture = null,
      },
      .scale = 1,
      .position = .{
        .x = 0,
        .y = 0,
        .z = 0,
      },
    };
    
    std.debug.assert(window.global.window != null);
    std.debug.assert(window.global.device != null);
    
    const texture_create_info: SDL.SDL_GPUTextureCreateInfo = .{
      .type = SDL.SDL_GPU_TEXTURETYPE_2D,
      .format = SDL.SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB,
      .usage = SDL.SDL_GPU_TEXTUREUSAGE_SAMPLER,
      .width = 1,
      .height = 1,
      .layer_count_or_depth = 1,
      .num_levels = 1,
      .sample_count = SDL.SDL_GPU_SAMPLECOUNT_1,
    };
    
    this.private.gpu_texture = SDL.SDL_CreateGPUTexture(window.global.device, &texture_create_info);
    if (this.private.gpu_texture == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    const transfer_buffer_create_info: SDL.SDL_GPUTransferBufferCreateInfo = .{
      .usage = SDL.SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
      .size = 4,
    };
    
    const transfer_buffer: ?*SDL.SDL_GPUTransferBuffer = SDL.SDL_CreateGPUTransferBuffer(window.global.device, &transfer_buffer_create_info);
    defer SDL.SDL_ReleaseGPUTransferBuffer(window.global.device, transfer_buffer);
    if (transfer_buffer == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    const transfer_buffer_beginning: ?*anyopaque = SDL.SDL_MapGPUTransferBuffer(window.global.device, transfer_buffer, false);
    defer SDL.SDL_UnmapGPUTransferBuffer(window.global.device, transfer_buffer);
    if (transfer_buffer_beginning == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    const single_white_pixel: [4]u8 = .{ 255, 255, 255, 255 };
    const memcpy_result: ?*anyopaque = SDL.SDL_memcpy(transfer_buffer_beginning, @ptrCast(&single_white_pixel[0]), 4);
    if (memcpy_result != transfer_buffer_beginning) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    window.frame.command_buffer = SDL.SDL_AcquireGPUCommandBuffer(window.global.device);
    if (window.frame.command_buffer == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    const copy_pass: ?*SDL.SDL_GPUCopyPass = SDL.SDL_BeginGPUCopyPass(window.frame.command_buffer);
    if (copy_pass == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    const texture_transfer_info: SDL.SDL_GPUTextureTransferInfo = .{
      .transfer_buffer = transfer_buffer,
      .pixels_per_row = 1,
      .rows_per_layer = 1,
    };
    
    const destination_texture_region: SDL.SDL_GPUTextureRegion = .{
      .texture = this.private.gpu_texture,
      .w = 1,
      .h = 1,
      .d = 1,
    };
    
    SDL.SDL_UploadToGPUTexture(copy_pass, &texture_transfer_info, &destination_texture_region, false);
    SDL.SDL_EndGPUCopyPass(copy_pass);
    if (!SDL.SDL_SubmitGPUCommandBuffer(window.frame.command_buffer)) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    window.frame.command_buffer = null;
    return this;
  }
  
  pub fn upload(this: *Mesh, vertices: []Vertex) void {
    std.debug.assert(window.global.window != null);
    std.debug.assert(window.global.device != null);
    
    this.private.num_vertices = 0;
    const release_existing_gpu_buffer: bool = (this.private.vertex_buffer != null);
    if (release_existing_gpu_buffer){
      SDL.SDL_ReleaseGPUBuffer(window.global.device, this.private.vertex_buffer);
      this.private.vertex_buffer = null;
    }
    
    const vertex_buffer_create_info: SDL.SDL_GPUBufferCreateInfo = .{
      .size = @intCast(vertices.len * @sizeOf(Vertex)),
      .usage = SDL.SDL_GPU_BUFFERUSAGE_VERTEX,
    };
    
    this.private.num_vertices = vertices.len;
    this.private.vertex_buffer = SDL.SDL_CreateGPUBuffer(window.global.device, &vertex_buffer_create_info);
    if (this.private.vertex_buffer == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    const transfer_buffer_create_info: SDL.SDL_GPUTransferBufferCreateInfo = .{
      .size = @intCast(vertices.len * @sizeOf(Vertex)),
      .usage = SDL.SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
    };
    
    const transfer_buffer: ?*SDL.SDL_GPUTransferBuffer = SDL.SDL_CreateGPUTransferBuffer(window.global.device, &transfer_buffer_create_info);
    defer SDL.SDL_ReleaseGPUTransferBuffer(window.global.device, transfer_buffer);
    if (transfer_buffer == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    const transfer_buffer_beginning: ?*anyopaque = SDL.SDL_MapGPUTransferBuffer(window.global.device, transfer_buffer, false);
    defer SDL.SDL_UnmapGPUTransferBuffer(window.global.device, transfer_buffer);
    if (transfer_buffer_beginning == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    const memcpy_result: ?*anyopaque = SDL.SDL_memcpy(transfer_buffer_beginning, @ptrCast(vertices), vertices.len * @sizeOf(Vertex));
    if (memcpy_result != transfer_buffer_beginning) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    window.frame.command_buffer = SDL.SDL_AcquireGPUCommandBuffer(window.global.device);
    if (window.frame.command_buffer == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    const copy_pass: ?*SDL.SDL_GPUCopyPass = SDL.SDL_BeginGPUCopyPass(window.frame.command_buffer);
    if (copy_pass == null) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    }
    
    const transfer_buffer_location: SDL.SDL_GPUTransferBufferLocation = .{
      .transfer_buffer = transfer_buffer,
    };
    
    const destination_buffer_region: SDL.SDL_GPUBufferRegion = .{
      .buffer = this.private.vertex_buffer,
      .size = @intCast(vertices.len * @sizeOf(Vertex)),
    };
    
    SDL.SDL_UploadToGPUBuffer(copy_pass, &transfer_buffer_location, &destination_buffer_region, true);
    SDL.SDL_EndGPUCopyPass(copy_pass);
    if (!SDL.SDL_SubmitGPUCommandBuffer(window.frame.command_buffer)) {
      std.debug.print("SDL Error: {s}\n", .{ SDL.SDL_GetError() });
      std.process.exit(EXIT_FAILURE);
    } window.frame.command_buffer = null;
  }
  
  pub fn draw(this: *Mesh) void {
    //const aspect_ratio: f64 = @as(f64, window.global.dimensions.x) / @as(f64, window.global.dimensions.y);
    const model_matrix: Matrix = .model(this.scale, this.position, this.private.quaternion);
    //const view_matrix: Matrix = .view(Camera.position, Camera.quaternion);
    const view_matrix: Matrix = .identity();
    //const projection_matrix: Matrix = .project(Camera.fov, aspect_ratio);
    const projection_matrix: Matrix = .identity();
    const mvp_matrix: Matrix = .mul(.mul(projection_matrix, view_matrix), model_matrix);
    SDL.SDL_PushGPUVertexUniformData(window.frame.command_buffer, 0, @ptrCast(&mvp_matrix.columnmajor()[0]), @intCast(@sizeOf(f32) * 16));
    
    std.debug.assert(this.private.vertex_buffer != null);
    std.debug.assert(this.private.gpu_texture != null);
    std.debug.assert(window.frame.render_pass != null);
    
    const buffer_binding: SDL.SDL_GPUBufferBinding = .{
      .buffer = this.private.vertex_buffer,
    };
    
    const texture_binding: SDL.SDL_GPUTextureSamplerBinding = .{
      .texture = this.private.gpu_texture,
      .sampler = window.global.sampler,
    };
    
    SDL.SDL_BindGPUVertexBuffers(window.frame.render_pass, 0, &buffer_binding, 1);
    SDL.SDL_BindGPUFragmentSamplers(window.frame.render_pass, 0, &texture_binding, 1);
    SDL.SDL_DrawGPUPrimitives(window.frame.render_pass, @intCast(this.private.num_vertices), 1, 0, 0);
  }
  
  pub fn destroy(this: *Mesh) void {
    this.scale = 1;
    this.position = .{ .x = 0, .y = 0, .z = 0 };
    this.private.num_vertices = 0;
    this.private.quaternion = .unit();
    
    const release_vertex_buffer: bool = (this.private.vertex_buffer != null);
    if (release_vertex_buffer) {
      std.debug.assert(window.global.device != null);
      SDL.SDL_ReleaseGPUBuffer(window.global.device, this.private.vertex_buffer);
      this.private.vertex_buffer = null;
    }
    
    const release_gpu_texture: bool = (this.private.gpu_texture != null);
    if (release_gpu_texture) {
      std.debug.assert(window.global.device != null);
      SDL.SDL_ReleaseGPUTexture(window.global.device, this.private.gpu_texture);
      this.private.gpu_texture = null;
    }
  }
};

